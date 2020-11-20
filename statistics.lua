--[[

	Sections
	========

	Copyright (C) 2020 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

minetest.register_chatcommand("section", {
	params = "",
	description = "Sektion anzeigen",
	privs = {interact=true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local number = sections.section_num(pos)
			local pos1, pos2 = sections.section_area(pos)
			sections.mark_region(name, pos1, pos2, number)
			return true, "Section number: "..number
		end
	end,
})

minetest.register_chatcommand("query", {
	params = "[<search-string>]",
	description = "Action Datenbank abfragen",
	privs = {superminer=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			for _,line in ipairs(sections.grep(pos, param)) do
				minetest.chat_send_player(name, line)
			end
		end
	end,
})

