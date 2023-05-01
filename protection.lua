--[[

	Sections
	========

	Copyright (C) 2020-2021 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end

------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local function serialize_names(item)
	local t = {tostring(item.owner) or "superminer"}
	for k,v in pairs(item.names or {}) do
		table.insert(t, tostring(v))
	end
	return table.concat(t, ",")
end

local function deserialize_names(s)
	local names = {}
	local owner = nil
	for n in s:gmatch("[^,]+") do
		if not owner then
			owner = n
		else
			names[#names + 1] = n
		end
	end
	return {owner = owner, names = names}
end

local function deserialize(s)
	local tbl = {}
	for line in s:gmatch("[^;]+") do
		local _, _, k, names = string.find(line, "([^=]+)=([^=]+)")
		tbl[k] = deserialize_names(names)
	end
	return tbl
end

local function serialize(data)
	local tbl = {}
	for k,v in pairs(data) do
		tbl[#tbl+1] = k.."="..serialize_names(v)
	end
	return table.concat(tbl, ";")
end

local function convertV1(s)
	local function old_section_pos(num)
		local _, _, z, zpos, x, xpos, y, ypos = string.find(num, "(%u)(%d+)(%u)(%d+)(%u)(%d+)")
		xpos = ((xpos * 48) - 8) * (x == "E" and -1 or 1)
		ypos = ((ypos * 48) - 8) * (y == "D" and -1 or 1)
		zpos = ((zpos * 48) - 8) * (z == "S" and -1 or 1)
		return {x = xpos, y = ypos, z = zpos}
	end

	local tbl1 = minetest.deserialize(s) or {}
	local tbl2 = {}
	
	for k,v in pairs(tbl1) do
		local pos = old_section_pos(k)
		for x = 0, 32, 16 do
		for y = 0, 32, 16 do
		for z = 0, 32, 16 do
			local num = sections.section_num({x = pos.x + x, y = pos.y + y, z = pos.z + z})
			tbl2[num] = v
		end
		end
		end
	end
	
	return tbl2
end

local storage = minetest.get_mod_storage()
local Version = minetest.deserialize(storage:get_string("Version")) or 2
local ProtectedSections = {}

if Version == 1 then
	ProtectedSections = convertV1(storage:get_string("ProtectedSections"))
	Version = 2
else
	ProtectedSections = deserialize(storage:get_string("ProtectedSections"))
end

local function update_mod_storage()
	local t = minetest.get_us_time()
	minetest.log("action", "[sections] Store data...")
	storage:set_string("ProtectedSections", serialize(ProtectedSections))
	storage:set_string("Version", minetest.serialize(Version))
	-- store data each hour
	minetest.after(60*60, update_mod_storage)
	t = minetest.get_us_time() - t
	minetest.log("action", "[sections] Data stored. t="..t.."us")
end

-- Convert table for a 16x16x16 section size (former 48x48x48)
if Version == 1 then
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*61, update_mod_storage)

-------------------------------------------------------------------------------
-- Protection functions
-------------------------------------------------------------------------------
local function find_surface(pos)
	local pos1 = table.copy(pos)
	for y = 1,16 do
		local node = minetest.get_node(pos1)
		if node.name ~= "air" then
			pos1.y = pos1.y + 1
			return pos1
		end
		pos1.y = pos1.y - 1
	end
end

local function place_markers(pos1, pos2)
	local pos
	
	pos = find_surface({x = pos1.x, y = pos2.y, z = pos1.z})
	if pos then
		minetest.add_node(pos, {name = "wool:yellow"})
	end
	pos = find_surface({x = pos2.x, y = pos2.y, z = pos2.z})
	if pos then
		minetest.add_node(pos, {name = "wool:yellow"})
	end
	pos = find_surface({x = pos2.x, y = pos2.y, z = pos1.z})
	if pos then
		minetest.add_node(pos, {name = "wool:yellow"})
	end
	pos = find_surface({x = pos1.x, y = pos2.y, z = pos2.z})
	if pos then
		minetest.add_node(pos, {name = "wool:yellow"})
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
		local sminer = minetest.check_player_privs(name, "superminer")
		local num = sections.section_num(pos)
		
		if not sminer and not has_area_rights(num, name) then
			return true
		end
	end
	return old_is_protected(pos, name)
end

function sections.get_owner(pos)
	local num = sections.section_num(pos)
	return get_owner(num)
end

function sections.protect_area(pos, caller, new_owner, names)
	--print("protect_area", caller, new_owner, dump(names))
	new_owner = new_owner or "superminer"
	names = names or {}
	for npos in sections.iter_sections(pos, "111") do
		local num = sections.section_num(npos)
		if not ProtectedSections[num] then
			ProtectedSections[num] = {owner = new_owner, names = names}
		end
		local pos1, pos2 = sections.section_area(npos)
		sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
	end
end

-------------------------------------------------------------------------------
-- Chat commands
-------------------------------------------------------------------------------
minetest.register_chatcommand("section_info", {
	params = "",
	description = "Output section owner and additional player names.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if ProtectedSections[num] then
				local pos1, pos2 = sections.section_area(pos)
				sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
				return true, "Your position is protected by: " .. get_names(num)
			end
			return true, "Your position is not protected."
		end
	end,
})

minetest.register_chatcommand("section_mark", {
	params = "",
	privs = {superminer = true},
	description = "Mark current section will wool blocks.",
	func = function(caller)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if ProtectedSections[num] then
				local pos1, pos2 = sections.section_area(pos)
				place_markers(pos1, pos2)
				return true, "Markers placed."
			end
			return true, "Your position is not protected."
		end
	end,
})

minetest.register_chatcommand("section_protect", {
	params = "<111/333/555>",
	privs = {superminer = true},
	description = "Protect current section(s) for superminers.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			local c1, c2 = 0, 0
			for npos in sections.iter_sections(pos, param) do
				local num = sections.section_num(npos)
				if not ProtectedSections[num] then
					ProtectedSections[num] = {owner = "superminer", names = {}}
					c1 = c1 + 1
				end
				c2 = c2 + 1
				local pos1, pos2 = sections.section_area(npos)
				sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
			end
			return true, c1 .. "/" .. c2 .. " section(s) protected."
		end
	end,
})

minetest.register_chatcommand("section_test", {
	params = "<111/333/555>",
	privs = {superminer = true},
	description = "Test current section(s) for protection.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		if player then
			local pos = vector.round(player:get_pos())
			local c1, c2 = 0, 0
			local protections = {}
			for npos in sections.iter_sections(pos, param) do
				local num = sections.section_num(npos)
				if ProtectedSections[num] then
					local s = P2S(vector.divide(vector.subtract(pos, npos), 16))
					table.insert(protections, s)
					c1 = c1 + 1
					local pos1, pos2 = sections.section_area(npos)
					sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
				end
				c2 = c2 + 1
			end
			if not next(protections) then
				return true, "No section is protected."
			else
				return true, c1 .. "/" .. c2 .. " section(s) protected: " .. table.concat(protections, ", ")
			end
		end
	end,
})

minetest.register_chatcommand("section_change_owner", {
	params = "<111/333/555> <name>",
	description = "Change the owner of the current section.",
	func = function(caller, params)
		local _, _, size, name = string.find(params, "^(%d+)%s+(%S+)$")
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		if size and player and name then
			local pos = vector.round(player:get_pos())
			local c1, c2 = 0, 0
			for npos in sections.iter_sections(pos, size) do
				local num = sections.section_num(npos)
				if ProtectedSections[num] and (sminer or is_owner(num, caller)) then
					ProtectedSections[num].owner = name
					ProtectedSections[num].names = {}
					c1 = c1 + 1
				end
				c2 = c2 + 1
			end
			return true, "Owner changed in " .. c1 .. "/" .. c2 .. " section(s)."
		else
			return false, "Syntax error: section_change_owner <111/333/555> <name>"
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
				return false, "Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				if ProtectedSections[num].owner ~= name then
					ProtectedSections[num].names[name] = true
					return true, "Player " .. name .. " added."
				end
				return false, "You can't add the owner as player."
			end
			return false, "You are not the owner of this section."
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
				return false, "Section is not protected."
			end
			if sminer or is_owner(num, caller) then
				if ProtectedSections[num].names[name] then
					ProtectedSections[num].names[name] = nil
					return true, "Player " .. name .. " removed."
				end
				return false, "Can't delete player " .. name
			end
			return false, "You are not the owner of this section."
		else
			return false, "Invalid player name."
		end
	end,
})

minetest.register_chatcommand("section_delete", {
	params = "<111/333/555>",
	description = "Delete current section(s) protection.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		local sminer = minetest.check_player_privs(caller, "superminer")
		if player then
			local pos = vector.round(player:get_pos())
			local c1, c2 = 0, 0
			for npos in sections.iter_sections(pos, param) do
				local num = sections.section_num(npos)
				if ProtectedSections[num] and (sminer or is_owner(num, caller)) then
					sections.unmark_region(caller)
					ProtectedSections[num] = nil
					c1 = c1 + 1
				end
				c2 = c2 + 1
			end
			return true, c1 .. "/" .. c2 .. " section(s) deleted."
		end
	end,
})
