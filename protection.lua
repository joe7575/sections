--[[

	Sections
	========

	Copyright (C) 2020-2024 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
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
local function find_surface(pos)
	local pos1 = table.copy(pos)
	for _ = 1,50 do
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
		local pos1, pos2 = sections.section_area(npos)
		sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
	end
	update_mod_storage()
end

-- Iterator over all sections in 'dimension'
--     @dimension - number of sections: <111/222/333/555>
--     @func(npos, caller, num, param)
--         @npos   - new position within section
--         @caller - chatcommand caller name
--         @num    - section number like 'S14W50U1'
--         @param  - further parameter
--         function returns true for success
--     @caller - chatcommand caller name
--     @param  - additional chatcommand parameter
local function for_all_positions(dimension, func, caller, param)
	local cnt = 0
	local visited_sections = {} 
	local player = minetest.get_player_by_name(caller)
	if player then
		local pos = vector.round(player:get_pos())
		for npos in sections.iter_sections(pos, dimension) do
			local num = sections.section_num(npos)
			if not visited_sections[num] then
				if func(npos, caller, num, param) then
					cnt = cnt + 1
				end
				visited_sections[num] = true
			end
		end
	end
	if cnt == 1 then
		return cnt, " ", "is "
	else
		return cnt, "s ", "are "
	end
end

-------------------------------------------------------------------------------
-- Chat commands
-------------------------------------------------------------------------------
minetest.register_chatcommand("section_info", {
	params = "<1/2/3/5> as dimension",
	description = "Output owner and additional player names for all sections",
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
		local cnt, plural, verb = for_all_positions(dimension, 
			function(pos, caller, num, param)
				if ProtectedSections[num] then
					local pos1, pos2 = sections.section_area(pos)
					sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
					local text = "Section " .. num .. " is protected by: " .. get_names(num)
					minetest.chat_send_player(caller, text)
					return true
				end
			end, 
		caller)
		return true, cnt .. " position" .. plural .. verb .. "protected."
	end,
})

minetest.register_chatcommand("section_mark", {
	params = "<1/2/3/5> as dimension",
	privs = {[sections.admin_privs] = true},
	description = "Mark the sections area with wool blocks",
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
		local minpos, maxpos
		for_all_positions(dimension, 
			function(pos, caller, num, param)
				if ProtectedSections[num] then
					local pos1, pos2 = sections.section_area(pos)
					minpos = minpos or pos1
					maxpos = pos2
					return true
				end
			end,
		caller)
		if minpos and maxpos then
			place_markers(minpos, maxpos)
			return true, "Markers placed."
		end
		return false, "Error: No markers placed!"
	end,
})

minetest.register_chatcommand("section_protect", {
	params = "<1/2/3/5> as dimension",
	privs = {[sections.admin_privs] = true},
	description = "Protect up to 125 sections around you",
	func = function(caller, dimension)
		sections.unmark_regions(caller) 
		local cnt, plural, _ = for_all_positions(dimension, 
			function(pos, caller, num, param)
				if not ProtectedSections[num] then
					ProtectedSections[num] = {owner = caller, names = {}}
					local pos1, pos2 = sections.section_area(pos)
					sections.mark_region(caller, pos1, pos2, ProtectedSections[num].owner)
					return true
				end
			end,
		caller)
		update_mod_storage()
		return true, cnt .. " section" .. plural .. "protected."
	end,
})

minetest.register_chatcommand("section_change_owner", {
	params = "<name> <1/2/3/5>",
	description = "Change the owner of up to 125 sections around you",
	func = function(caller, params)
		sections.unmark_regions(caller) 
		local _, _, name, dimension = string.find(params, "^(%S+)%s+(%d+)$")
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		if dimension and name then
			local cnt, plural, _ = for_all_positions(dimension, 
				function(pos, caller, num, name)
					if ProtectedSections[num] and (is_admin or is_owner(num, caller)) then
						ProtectedSections[num].owner = name
						ProtectedSections[num].names = {}
						local pos1, pos2 = sections.section_area(pos)
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
	description = "Add an extra player to the sections around you",
	func = function(caller, params)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local _, _, name, dimension = string.find(params, "^(%S+)%s+(%d+)$")
		if dimension and name then
			local cnt, plural, _ = for_all_positions(dimension, 
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
	params = "<name>",
	description = "Delete one addition player from the current section.",
	func = function(caller, param)
		local player = minetest.get_player_by_name(caller)
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		local name = param:match("^(%S+)$")
		if player and name then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			if not ProtectedSections[num] then
				return false, "Section is not protected."
			end
			if is_admin or is_owner(num, caller) then
				if ProtectedSections[num].names[name] then
					ProtectedSections[num].names[name] = nil
					update_mod_storage()
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
		local is_admin = minetest.check_player_privs(caller, sections.admin_privs)
		if player then
			local pos = vector.round(player:get_pos())
			local c1, c2 = 0, 0
			for npos in sections.iter_sections(pos, param) do
				local num = sections.section_num(npos)
				if ProtectedSections[num] and (is_admin or is_owner(num, caller)) then
					sections.unmark_region(caller)
					ProtectedSections[num] = nil
					c1 = c1 + 1
				end
				c2 = c2 + 1
			end
			update_mod_storage()
			return true, c1 .. "/" .. c2 .. " section(s) deleted."
		end
	end,
})
