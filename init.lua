--[[

	Sections
	========

	Copyright (C) 2020 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

-- Sections (32x32x32 blocks) used for protection areas, statistics and more

sections = {}
dofile(minetest.get_modpath("sections") .. "/mark.lua")
dofile(minetest.get_modpath("sections") .. "/lib.lua")
dofile(minetest.get_modpath("sections") .. "/statistics.lua")
dofile(minetest.get_modpath("sections") .. "/protection.lua")

print("[sections] Mod loaded")