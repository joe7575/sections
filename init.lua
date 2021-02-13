--[[

	Sections
	========

	Copyright (C) 2020-2021 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

-- Sections (48x48x48 blocks) used for protection areas, statistics and more

sections = {}
dofile(minetest.get_modpath("sections") .. "/mark.lua")
dofile(minetest.get_modpath("sections") .. "/lib.lua")
dofile(minetest.get_modpath("sections") .. "/statistics.lua")
dofile(minetest.get_modpath("sections") .. "/protection.lua")

print("[sections] Mod loaded")