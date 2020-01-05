local logging = sections.logging
local grep = sections.grep
local section_num = sections.section_num
local section_area = sections.section_area

minetest.register_on_dignode(function(pos, oldnode, digger)
	logging(pos, digger:get_player_name(), "digs", oldnode)
end)

minetest.register_on_placenode(function(pos, newnode, placer)
	logging(pos, placer:get_player_name(), "places", newnode)
end)

minetest.register_chatcommand("section", {
	params = "",
	description = "Sektion anzeigen",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local number = section_num(pos)
			local pos1, pos2 = section_area(pos)
			sections.mark_region(name, pos1, pos2, number)
		end
	end,
})

minetest.register_chatcommand("query", {
	params = "[<search-string>]",
	description = "Action Datenbank abfragen.",
	privs = {superminer=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			for _,line in ipairs(grep(pos, param or "")) do
				minetest.chat_send_player(name, line)
			end
		end
	end,
})

