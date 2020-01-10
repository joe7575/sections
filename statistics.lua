local logging = sections.logging
local grep = sections.grep
local section_num = sections.section_num
local section_area = sections.section_area

minetest.register_on_dignode(function(pos, oldnode, digger)
	if digger and minetest.is_player(digger) then
		logging(pos, digger:get_player_name(), "digs", oldnode)
	end
end)

minetest.register_on_placenode(function(pos, newnode, placer)
	if placer and minetest.is_player(placer) then
		logging(pos, placer:get_player_name(), "places", newnode)
	end
end)

minetest.register_chatcommand("section", {
	params = "",
	description = "Sektion anzeigen",
	privs = {superminer=true},
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
	params = "<day-num> [<search-string>]",
	description = "Action Datenbank abfragen. day-num = 0 für heute, -1 für gestern, usw.",
	privs = {superminer=true},
	func = function(name, param)
		local days, search = unpack(string.split(param, " "))
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			days = tonumber(days or "0") or 0
			search = search or ""
			for _,line in ipairs(grep(pos, days, search)) do
				minetest.chat_send_player(name, line)
			end
		end
	end,
})

