--[[

	Sections
	========

	Copyright (C) 2020-2024 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

-- Sections (16x16x16 blocks) used for protection areas, statistics and more

sections = {}
sections.admin_privs = minetest.settings:get("sections_admin_privs")

dofile(minetest.get_modpath("sections") .. "/mark.lua")
dofile(minetest.get_modpath("sections") .. "/lib.lua")
dofile(minetest.get_modpath("sections") .. "/statistics.lua")
dofile(minetest.get_modpath("sections") .. "/protection.lua")

print("[sections] Mod loaded")