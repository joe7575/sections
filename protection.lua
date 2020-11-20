--[[

	Sections
	========

	Copyright (C) 2020 Joachim Stolberg

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

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*61, update_mod_storage)

------------------------------------------------------------------
-- Protection functions
-------------------------------------------------------------------
local old_is_protected = minetest.is_protected

-- check for protected area, return true if protected
function minetest.is_protected(pos, name)
	if name and name ~= "" then
		local sminer = minetest.check_player_privs(name, "superminer")
		local num = sections.section_num(pos)
		
		if not sminer and ProtectedSections[num] then
			return true
		end
	end
	return old_is_protected(pos, name)
end


minetest.register_chatcommand("section_info", {
	params = "",
	privs = {superminer = true},
	description = "Output section state.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			local state = ProtectedSections[num]
			if state then
				return true, num..": Your position is protected."
			else
				return true, num..": Your position is not protected."
			end
		end
	end,
})

minetest.register_chatcommand("protect_section", {
	params = "",
	privs = {superminer = true},
	description = "Protect current section for you.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			ProtectedSections[num] = true
			return true, num..": Protection added."
		end
	end,
})

minetest.register_chatcommand("delete_section", {
	params = "",
	privs = {sections = true},
	description = "Delete current protection.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local num = sections.section_num(pos)
			ProtectedSections[num] = nil
			return true, num..": Protection deleted."
		end
	end,
})

