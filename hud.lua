--[[
  Sections is a landscape protection mod for the game Minetest.
  Copyright (C) 2023-2024 Joachim Stolberg <iauit@gmx.de>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

local S = sections.S

local hud = {}
local hud_timer = 0

-- This HUD only shows section ownership. Protector block owners are shown by
-- the protector mod's own HUD (if enabled via protector_hud_interval).
local function get_hud_text(pos)
	local owner = sections.get_owner(pos)
	if owner then
		return S("Owner: @1 [Section]", owner)
	end
	return ""
end

minetest.register_globalstep(function(dtime)
	-- every 5 seconds
	hud_timer = hud_timer + dtime
	if hud_timer < 5 then
		return
	end
	hud_timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:get_pos())
		local hud_text = get_hud_text(pos)

		if not hud[name] then
			hud[name] = {}
			hud[name].id = player:hud_add({
				type = "text",
				name = "Protection Area",
				number = 0xFFFF22,
				position = {x = 0, y = 0.93},
				offset = {x = 8, y = -8},
				text = hud_text,
				scale = {x = 200, y = 30},
				alignment = {x = 1, y = -1},
			})
		else
			player:hud_change(hud[name].id, "text", hud_text)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	hud[player:get_player_name()] = nil
end)
