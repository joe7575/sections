--[[

	Sections
	========

	Copyright (C) 2020-2021 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local ProtectedSections = minetest.deserialize(storage:get_string("ProtectedSections")) or {}
local Version = minetest.deserialize(storage:get_string("Version")) or 1

local function update_mod_storage()
	local t = minetest.get_us_time()
	minetest.log("action", "[sections] Store data...")
	storage:set_string("ProtectedSections", minetest.serialize(ProtectedSections))
	storage:set_string("Version", minetest.serialize(Version))
	-- store data each hour
	minetest.after(60*60, update_mod_storage)
	t = minetest.get_us_time() - t
	minetest.log("action", "[sections] Data stored. t="..t.."us")
end

-- Convert table for adding player names
for k,v in pairs(ProtectedSections) do
	if v == true then
		ProtectedSections[k] = {owner = "superminer", names = {}}
	end
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*61, update_mod_storage)

------------------------------------------------------------------
-- Protection functions
-------------------------------------------------------------------
local Offsets = {}

for x = -32, 32, 32 do
	for y = -32, 32, 32 do
		for z = -32, 32, 32 do
			table.insert(Offsets, {x = x, y = y, z = z})
		end
	end
end

local function get_surrounding(pos)
	local i = 0
    local n = table.getn(Offsets)
    return function ()
		i = i + 1
		if i <= n then 
			return vector.add(pos, Offsets[i])
		end
	end
end

local function get_owner(num)
	local items = ProtectedSections[num]
	if not items then return end
	return ProtectedSections[num].owner or "superminer"
end

local function is_owner(num, name)
	local items = ProtectedSections[num]
	if not items then return end
	return ProtectedSections[num].owner == name
end

local function get_names(num)
	local t = {}
	local owner = (ProtectedSections[num].owner or "superminer") .. " ("
	for k,v in pairs(ProtectedSections[num].names or {}) do
		table.insert(t, k)
	end
	return owner .. table.concat(t, ", ") .. ")"
end

local function has_area_rights(num, name)
	local items = ProtectedSections[num]
	if not items then return end
	if ProtectedSections[num].owner == name then
		return true
	end
	return ProtectedSections[num].names[name]
end
	
local old_is_protected = minetest.is_protected

-- check for protected area, return true if protected
function minetest.is_protected(pos, name)
	if name and name ~= "" then
		local sminer = minetest.check_player_privs(name, "superminer")
		local num = sections.section_num(pos)
		
		if not sminer and not has_area_rights(num, name) then
			return true
		end
	end
	return old_is_protected(pos, name)
end


minetest.register_chatcommand("section_info", {
	params = "",
	description = "Output section owner and additional player names.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			local items = ProtectedSections[num]
			if items then
				local pos1, pos2 = sections.section_area(pos)
				sections.mark_region(name, pos1, pos2, num)
				return true, num..": Your position is protected by: " .. get_names(num)
			else
				return true, num..": Your position is not protected."
			end
		end
	end,
})

minetest.register_chatcommand("section_protect", {
	params = "",
	privs = {superminer = true},
	description = "Protect current section for superminers.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if ProtectedSections[num] then
				return false, num..": Section already protected."
			end
			ProtectedSections[num] = {owner = "superminer", names = {}}
			return true, num..": Section protected."
		end
	end,
})

minetest.register_chatcommand("section_test27", {
	params = "",
	privs = {superminer = true},
	description = "Test current section and all sections around it.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			for pos2 in get_surrounding(pos) do
				local num = sections.section_num(pos2)
				if ProtectedSections[num] then
					return false, num..": Section already protected by " .. ProtectedSections[num].owner
				end
			end
			return true, "No section is protected."
		end
	end,
})

minetest.register_chatcommand("section_protect27", {
	params = "",
	privs = {superminer = true},
	description = "Protect current section and all sections around it for superminers.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			for pos2 in get_surrounding(pos) do
				local num = sections.section_num(pos2)
				if not ProtectedSections[num] then
					ProtectedSections[num] = {owner = "superminer", names = {}}
				end
			end
			return true, "All sections protected."
		end
	end,
})

minetest.register_chatcommand("section_change_owner", {
	params = "<name>",
	description = "Change the owner of the current section.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		local name = param:match("^(%S+)$")
		if player and name then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not ProtectedSections[num] then
				return false, num..": Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				ProtectedSections[num].owner = name
				ProtectedSections[num].names = {}
				return true, num..": Section owner changed."
			end
			return false, num..": You are not the owner of this section."
		else
			return false, "Invalid player name."
		end
	end,
})

minetest.register_chatcommand("section_add_player", {
	params = "<name>",
	description = "Add an additional player to the current section.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		local name = param:match("^(%S+)$")
		if player and name then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not ProtectedSections[num] then
				return false, num..": Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				if ProtectedSections[num].owner ~= name then
					ProtectedSections[num].names[name] = true
					return true, num..": Player " .. name .. " added."
				end
				return false, "You can't add the owner as player."
			end
			return false, num..": You are not the owner of this section."
		else
			return false, "Invalid player name."
		end
	end,
})

minetest.register_chatcommand("section_delete_player", {
	params = "<name>",
	description = "Delete one addition player from the current section.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		local name = param:match("^(%S+)$")
		if player and name then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not ProtectedSections[num] then
				return false, num..": Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				if ProtectedSections[num].names[name] then
					ProtectedSections[num].names[name] = nil
					return true, num..": Player " .. name .. " removed."
				end
				return false, num..": Can't delete player " .. name
			end
			return false, num..": You are not the owner of this section."
		else
			return false, "Invalid player name."
		end
	end,
})

minetest.register_chatcommand("section_delete", {
	params = "",
	description = "Delete current protection.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not ProtectedSections[num] then
				return false, num..": Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				sections.unmark_region(caller)
				ProtectedSections[num] = nil
				return true, num..": Protection deleted."
			end
			return false, num..": You are not the owner of this section."
		end
	end,
})

function sections.get_owner(pos)
	local num = sections.section_num(pos)
	return get_owner(num)
end