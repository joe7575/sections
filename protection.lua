--[[
  Sections is a landscape protection mod for the game Minetest.
  Copyright (C) 2023-2024 Joachim Stolberg <iauit@gmx.de>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S = sections.S
local HELP = S("\n(The parameter selects 1, 2x2, 3x3, or 5x5 sections in X/Z;\nY always covers the 4 sections -1, 0, +1, +2)")

-- Same settings the Section Protection Tool uses, mirrored here so that
-- /section_delete can refund the cost.
local COST_ITEM = minetest.settings:get("sections_tool_cost_item") or "default:diamond"
local COST_COUNT = tonumber(minetest.settings:get("sections_tool_cost_count")) or 4

------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------

local function convertV2(s)
	local tbl = {}
	for line in s:gmatch("[^;]+") do
		local _, _, k, _ = string.find(line, "([^=]+)=([^=]+)")
		tbl[k] = {owner = sections.admin_privs, names = {}}
	end
	return tbl
end

local storage = minetest.get_mod_storage()
local Version = minetest.deserialize(storage:get_string("Version")) or 3
local ProtectedSections = {}

local function update_mod_storage()
	storage:set_string("ProtectedSections", minetest.serialize(ProtectedSections))
	storage:set_string("Version", minetest.serialize(Version))
end

if Version == 2 then
	ProtectedSections = convertV2(storage:get_string("ProtectedSections")) or {}
	Version = 3
	update_mod_storage()
else
	ProtectedSections = minetest.deserialize(storage:get_string("ProtectedSections")) or {}
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- Expose internals so sections_import can merge data at startup
sections.ProtectedSections = ProtectedSections
sections.save = update_mod_storage

-------------------------------------------------------------------------------
-- Protection functions
-------------------------------------------------------------------------------
local function get_owner(num)
	local items = ProtectedSections[num]
	if not items then return end
	return ProtectedSections[num].owner or sections.admin_privs
end

local function is_owner(num, name)
	local items = ProtectedSections[num]
	if not items then return end
	return ProtectedSections[num].owner == name
end

local function get_names(num)
	local owner = ProtectedSections[num].owner or sections.admin_privs
	local tbl = {"[" .. owner  .. "]"}
	for k,_ in pairs(ProtectedSections[num].names or {}) do
		table.insert(tbl, k)
	end
	return table.concat(tbl, ", ")
end

local function has_area_rights(num, name)
	local items = ProtectedSections[num]
	if not items then return true end
	if ProtectedSections[num].owner == name then
		return true
	end
	return ProtectedSections[num].names[name]
end

local old_is_protected = minetest.is_protected

-- check for protected area, return true if protected
function minetest.is_protected(pos, name)
	if name and name ~= "" then
		local is_admin = minetest.check_player_privs(name, sections.admin_privs)
		local num = sections.section_num(pos)

		if not is_admin and not has_area_rights(num, name) then
			return true
		end
	end
	return old_is_protected(pos, name)
end

function sections.protect_section(caller, dimension, names)
	local cnt, plural = sections.for_all_positions(dimension,
		function(pos, caller, num, param)
			if not ProtectedSections[num] then
				ProtectedSections[num] = {owner = caller, names = names or {}}
				return true
			end
		end,
	caller)
	sections.mark_current_section(caller)
	update_mod_storage()
	return cnt, plural
end

function sections.get_owner(pos)
	local num = sections.section_num(pos)
	return get_owner(num)
end

-------------------------------------------------------------------------------
-- Admin chat commands
-------------------------------------------------------------------------------
minetest.register_chatcommand("section_mark", {
	params = "[1/2/3/5]",
	privs = {[sections.admin_privs] = true},
	description = S("Mark the corners of the outer boundaries of all selected sectors with wool blocks.") .. HELP,
	func = function(caller, dimension)
		if dimension == "" then dimension = "1" end
		local minpos, maxpos
		sections.for_all_positions(dimension,
			function(pos, caller, num, param)
				if ProtectedSections[num] then
					local pos1, pos2 = sections.section_corners(pos)
					minpos = minpos or pos1
					maxpos = pos2
					return true
				end
			end,
		caller)
		sections.mark_current_section(caller)
		if minpos and maxpos then
			local tbl = sections.place_markers(minpos, maxpos)
			for _, pos in ipairs(tbl) do
				local text = S("Marker placed at @1", P2S(pos))
				minetest.chat_send_player(caller, text)
		end
			return true, S("@1 markers placed", tostring(#tbl))
		end
		return false, S("Error: No markers placed!")
	end,
})

minetest.register_chatcommand("section_protect", {
	params = "[1/2/3/5]",
	privs = {[sections.admin_privs] = true},
	description = S("Protect the section(s) around you.") .. HELP,
	func = function(caller, dimension)
		if dimension == "" then dimension = "1" end
		local cnt, plural = sections.protect_section(caller, dimension)
		return true, S("@1 section@2 protected", tostring(cnt), plural)
	end,
})

-------------------------------------------------------------------------------
-- Player chat commands
-------------------------------------------------------------------------------
minetest.register_chatcommand("section_change_owner", {
	params = "<name>",
	description = S("Change the owner of the section you are in."),
	privs = {interact = true},
	func = function(caller, params)
		local _, _, name = string.find(params, "^(%S+)$")
		if not name then
			return false, S("Syntax error: section_change_owner <name>")
		end
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local player = minetest.get_player_by_name(caller)
		if not player then
			return false, S("Player not found.")
		end
		local pos = vector.round(player:get_pos())
		local num = sections.section_num(pos)
		if not ProtectedSections[num] then
			return false, S("This section is not protected.")
		end
		if not (is_admin or is_owner(num, caller)) then
			return false, S("You are not the owner of this section.")
		end
		ProtectedSections[num].owner = name
		ProtectedSections[num].names = {}
		sections.mark_current_section(caller)
		update_mod_storage()
		minetest.chat_send_player(caller,
			S("Owner of section @1 changed to @2", num, name))
		return true, S("Owner of section @1 changed to @2", num, name)
	end,
})

minetest.register_chatcommand("section_add_player", {
	params = "<name>",
	description = S("Add an extra player to the section you are in."),
	privs = {interact = true},
	func = function(caller, params)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local _, _, name = string.find(params, "^(%S+)$")
		if name then
			local player = minetest.get_player_by_name(caller)
			if not player then
				return false, S("Player not found.")
			end
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not (is_admin or is_owner(num, caller)) then
				minetest.chat_send_player(caller,
					S("You are not the owner of section @1", num))
				return false, S("You are not the owner of this section.")
			end
			if not ProtectedSections[num] then
				return false, S("This section is not protected.")
			end
			if ProtectedSections[num].owner == name then
				return false, S("@1 is the owner, no need to add.", name)
			end
			if ProtectedSections[num].names[name] then
				return false, S("@1 already has access to this section.", name)
			end
			ProtectedSections[num].names[name] = true
			sections.mark_current_section(caller)
			update_mod_storage()
			minetest.chat_send_player(caller,
				S("Name '@1' added to section @2", name, num))
			return true, S("Name '@1' added to section @2", name, num)
		else
			return false, S("Syntax error: section_add_player <name>")
		end
	end,
})

minetest.register_chatcommand("section_remove_player", {
	params = "<name>",
	description = S("Remove a player from the section you are in."),
	privs = {interact = true},
	func = function(caller, params)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local _, _, name = string.find(params, "^(%S+)$")
		if name then
			local player = minetest.get_player_by_name(caller)
			if not player then
				return false, S("Player not found.")
			end
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not (is_admin or is_owner(num, caller)) then
				minetest.chat_send_player(caller,
					S("You are not the owner of section @1", num))
				return false, S("You are not the owner of this section.")
			end
			if not ProtectedSections[num] then
				return false, S("This section is not protected.")
			end
			if not ProtectedSections[num].names[name] then
				return false, S("@1 has no access to this section.", name)
			end
			ProtectedSections[num].names[name] = nil
			sections.mark_current_section(caller)
			update_mod_storage()
			minetest.chat_send_player(caller,
				S("Name '@1' removed from section @2", name, num))
			return true, S("Name '@1' removed from section @2", name, num)
		else
			return false, S("Syntax error: section_remove_player <name>")
		end
	end,
})

-- Backwards-compatible alias for the old name.
minetest.register_chatcommand("section_delete_player", {
	params = "<name>",
	description = S("Alias for /section_remove_player."),
	privs = {interact = true},
	func = function(caller, params)
		return minetest.registered_chatcommands["section_remove_player"].func(caller, params)
	end,
})

-- /section_info was removed: the Section Protection Tool now shows the owner
-- and member list when left-clicking a block, so the command is redundant.

minetest.register_chatcommand("section_delete", {
	params = "",
	description = S("Delete the section you are in (and the three sections above/below it)."),
	privs = {interact = true},
	func = function(caller, dimension)
		sections.unmark_sections(caller)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local cnt, plural = sections.for_all_positions("1",
			function(pos, caller, num, name)
				if ProtectedSections[num] and (is_admin or is_owner(num, caller)) then
					ProtectedSections[num] = nil
					return true
				end
			end,
		caller)
		update_mod_storage()
		-- Refund the protection cost to the caller, even if only one or a
		-- few sections were actually released. Mirrors the flat cost the
		-- tool charges per /section_protect call.
		if cnt > 0 then
			local player = minetest.get_player_by_name(caller)
			if player then
				player:get_inventory():add_item("main",
					{name = COST_ITEM, count = COST_COUNT})
				minetest.chat_send_player(caller,
					S("@1 x @2 refunded", tostring(COST_COUNT), COST_ITEM))
			end
		end
		return true, S("@1 section@2deleted", tostring(cnt), plural)
	end,
})
