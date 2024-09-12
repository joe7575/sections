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
	ProtectedSections = convertV2(storage:get_string("ProtectedSections"))
	Version = 3
	update_mod_storage()
else
	ProtectedSections = minetest.deserialize(storage:get_string("ProtectedSections"))
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

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

function sections.get_owner(pos)
	local num = sections.section_num(pos)
	return get_owner(num)
end

-- Used by mytools
function sections.protect_area(pos, caller, new_owner, names)
	new_owner = new_owner or sections.admin_privs
	names = names or {}
	for npos in sections.iter_sections(pos, "111") do
		local num = sections.section_num(npos)
		if not ProtectedSections[num] then
			ProtectedSections[num] = {owner = new_owner, names = names}
		end
		local pos1, pos2 = sections.section_corners(npos)
		sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
	end
	update_mod_storage()
end

-------------------------------------------------------------------------------
-- Chat commands
-------------------------------------------------------------------------------
minetest.register_chatcommand("section", {
	params = "",
	description = "Display the section number on the HUD",
	privs = {interact = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local number = sections.section_num(pos)
			local pos1, pos2 = sections.section_corners(pos)
			sections.mark_region(name, pos1, pos2, number)
			return true, "Section number: "..number
		end
	end,
})

minetest.register_chatcommand("section_info", {
	params = "<1/2/3/5> as dimension",
	description = "Output owner and additional player names for the section(s) around you",
	privs = {interact = true},
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
		local cnt, plural, verb = sections.for_all_positions(dimension, 
			function(pos, caller, num, param)
				if ProtectedSections[num] then
					local pos1, pos2 = sections.section_corners(pos)
					sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
					local text = "Section " .. num .. " is protected by: " .. get_names(num)
					minetest.chat_send_player(caller, text)
					return true
				end
			end, 
		caller)
		return true, cnt .. " section" .. plural .. verb .. "protected"
	end,
})

minetest.register_chatcommand("section_mark", {
	params = "<1/2/3/5> as dimension",
	privs = {[sections.admin_privs] = true},
	description = "Mark the section area with wool blocks",
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
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
		if minpos and maxpos then
			sections.place_markers(minpos, maxpos)
			return true, "Markers placed"
		end
		return false, "Error: No markers placed!"
	end,
})

minetest.register_chatcommand("section_protect", {
	params = "<1/2/3/5> as dimension",
	privs = {[sections.admin_privs] = true},
	description = "Protect the section(s) around you",
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
		local cnt, plural, _ = sections.for_all_positions(dimension, 
			function(pos, caller, num, param)
				if not ProtectedSections[num] then
					ProtectedSections[num] = {owner = caller, names = {}}
					local pos1, pos2 = sections.section_corners(pos)
					sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
					return true
				end
			end,
		caller)
		update_mod_storage()
		return true, cnt .. " section" .. plural .. " protected"
	end,
})

minetest.register_chatcommand("section_change_owner", {
	params = "<name> <1/2/3/5>",
	description = "Change the owner of the section(s) around you",
	privs = {interact = true},
	func = function(caller, params)
		sections.unmark_regions(caller) 
		local _, _, name, dimension = string.find(params, "^(%S+)%s+(%d+)$")
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		if dimension and name then
			local cnt, plural, _ = sections.for_all_positions(dimension, 
				function(pos, caller, num, name)
					if ProtectedSections[num] and (is_admin or is_owner(num, caller)) then
						ProtectedSections[num].owner = name
						ProtectedSections[num].names = {}
						local pos1, pos2 = sections.section_corners(pos)
						sections.mark_region(caller, pos1, pos2, name)
						return true
					end
				end,
			caller, name)
			update_mod_storage()
			return true, "Owner changed for " .. cnt .. " section" .. plural
		else
			return false, "Syntax error: section_change_owner <name> <1/2/3/5>"
		end
	end,
})

minetest.register_chatcommand("section_add_player", {
	params = "<name> <1/2/3/5>",
	description = "Add an extra player to the section(s) around you",
	privs = {interact = true},
	func = function(caller, params)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local _, _, name, dimension = string.find(params, "^(%S+)%s+(%d+)$")
		if dimension and name then
			local cnt, plural, _ = sections.for_all_positions(dimension, 
				function(pos, caller, num, name)
					if is_admin or is_owner(num, caller) then
						if ProtectedSections[num].owner ~= name then
							ProtectedSections[num].names[name] = true
							local text = "Name '" .. name .. "' added for section " .. num
							minetest.chat_send_player(caller, text)
							return true
						end
					else
						local text = "You are not the owner of section " .. num
						minetest.chat_send_player(caller, text)
					end
				end,
			caller, name)
			update_mod_storage()
			return true, "Name '" .. name .. "' added at " .. cnt .. " section" .. plural
		else
			return false, "Syntax error: section_add_player <name> <1/2/3/5>"
		end
	end,
})

minetest.register_chatcommand("section_delete_player", {
	params = "<name> <1/2/3/5>",
	description = "Delete an extra player at the section(s) around you",
	privs = {interact = true},
	func = function(caller, params)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local _, _, name, dimension = string.find(params, "^(%S+)%s+(%d+)$")
		if dimension and name then
			local cnt, plural, _ = sections.for_all_positions(dimension, 
				function(pos, caller, num, name)
					if is_admin or is_owner(num, caller) then
						if ProtectedSections[num].owner ~= name then
							ProtectedSections[num].names[name] = nil
							local text = "Name '" .. name .. "' deleted at section " .. num
							minetest.chat_send_player(caller, text)
							return true
						end
					else
						local text = "You are not the owner of section " .. num
						minetest.chat_send_player(caller, text)
					end
				end,
			caller, name)
			update_mod_storage()
			return true, "Name '" .. name .. "' deleted " .. cnt .. " section" .. plural
		else
			return false, "Syntax error: section_delete_player <name> <1/2/3/5>"
		end
	end,
})

minetest.register_chatcommand("section_delete", {
	params = "<1/2/3/5>",
	description = "Delete the section(s) around you",
	privs = {interact = true},
	func = function(caller, dimension)
		sections.unmark_regions(caller)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local cnt, plural, _ = sections.for_all_positions(dimension, 
			function(pos, caller, num, name)
				if ProtectedSections[num] and (is_admin or is_owner(num, caller)) then
					ProtectedSections[num] = nil
					return true
				end
			end,
		caller)
		update_mod_storage()
		return true, cnt .. " section" .. plural .. "deleted"
	end,
})
