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

-------------------------------------------------------------------------------
-- Local helper functions
-------------------------------------------------------------------------------
local OffsetsXZ1 = {}
local OffsetsXZ2 = {}
local OffsetsXZ3 = {}
local OffsetsXZ5 = {}
local OFFSET = tonumber(minetest.settings:get("sections_grid_offset")) or 0

-- X/Z-only offsets (Y is handled separately by the Y-stack below)
table.insert(OffsetsXZ1, {x = 0,  z = 0})
for _, xz in ipairs({{-8,0},{8,0},{0,-8},{0,8}}) do
	table.insert(OffsetsXZ2, {x = xz[1], z = xz[2]})
end
for x = -16, 16, 16 do
	for z = -16, 16, 16 do
		table.insert(OffsetsXZ3, {x = x, z = z})
	end
end
for x = -32, 32, 16 do
	for z = -32, 32, 16 do
		table.insert(OffsetsXZ5, {x = x, z = z})
	end
end

-- Always 4 sections in Y: -1, 0, +1, +2 (relative to the section containing 'pos')
local YStack = {
	{x = 0, y = -16, z = 0}, -- -1
	{x = 0, y =   0, z = 0}, --  0
	{x = 0, y =  16, z = 0}, -- +1
	{x = 0, y =  32, z = 0}, -- +2
}

local function find_surface(pos)
	local pos1 = table.copy(pos)
	for _ = 1,50 do
		local node = minetest.get_node(pos1)
		local cnt = 10
		while node.name == "ignore" and cnt > 0 do
			minetest.load_area(pos1)
			node = minetest.get_node(pos1)
			cnt = cnt - 1
		end
		if node.name ~= "air" then
			local ndef = minetest.registered_nodes[node.name]
			if ndef and not ndef.buildable_to then
				pos1.y = pos1.y + 1
				return pos1
			end
		end
		pos1.y = pos1.y - 1
	end
end

-- Returns an iterator over a 1x4 / 2x4 / 3x4 / 5x4 stack of sections:
-- the X/Z layout is selected by 'dimension' (1, 2, 3, or 5),
-- the Y layout is always the 4 sections -1, 0, +1, +2 relative to the
-- section that contains 'pos'. The base position is the XZ center of the
-- section containing 'pos' (Y from 'pos').
local function iter_xz_sections(pos, dimension)
	local xz_tbl
	if dimension == "2" then
		xz_tbl = OffsetsXZ2
	elseif dimension == "3" then
		xz_tbl = OffsetsXZ3
	elseif dimension == "5" then
		xz_tbl = OffsetsXZ5
	else
		xz_tbl = OffsetsXZ1
	end
	local i = 0
	return function()
		i = i + 1
		local xz = xz_tbl[((i - 1) % #xz_tbl) + 1]
		local y  = YStack[math.floor((i - 1) / #xz_tbl) + 1]
		if xz and y then
			return {x = pos.x + xz.x, y = pos.y + y.y, z = pos.z + xz.z}
		end
	end
end

-------------------------------------------------------------------------------
-- API functions
-------------------------------------------------------------------------------
function sections.section_num(pos)
	local xpos = math.floor((pos.x + OFFSET) / 16)
	local ypos = math.floor((pos.y + OFFSET) / 16)
	local zpos = math.floor((pos.z + OFFSET) / 16)
	if xpos < 0 then
		xpos = "E"..(-xpos)
	else
		xpos = "W"..xpos
	end
	if zpos < 0 then
		zpos = "S"..(-zpos)
	else
		zpos = "N"..zpos
	end
	if ypos < 0 then
		ypos = "D"..(-ypos)
	else
		ypos = "U"..ypos
	end
	return zpos..xpos..ypos
end

-- Returns the two corner positions of the section with the smallest 
-- and largest coordinates.
function sections.section_corners(pos)
	local xpos = (math.floor((pos.x + OFFSET) / 16) * 16) - OFFSET
	local ypos = (math.floor((pos.y + OFFSET) / 16) * 16) - OFFSET
	local zpos = (math.floor((pos.z + OFFSET) / 16) * 16) - OFFSET
	local pos1 = {x = xpos, y = ypos, z = zpos}
	local pos2 = {x = xpos + 15, y = ypos + 15, z = zpos + 15}
	return pos1, pos2
end

function sections.section_center(pos)
	local xpos = (math.floor((pos.x + OFFSET) / 16) * 16) - OFFSET
	local ypos = (math.floor((pos.y + OFFSET) / 16) * 16) - OFFSET
	local zpos = (math.floor((pos.z + OFFSET) / 16) * 16) - OFFSET
	return {x = xpos + 7.5, y = ypos + 7.5, z = zpos + 7.5}
end

-- Place wool blocks in all 4 corners of the section area
function sections.place_markers(pos1, pos2)
	local pos
	local tbl = {}
	
	pos = find_surface({x = pos1.x, y = pos2.y, z = pos1.z})
	if pos then
		minetest.set_node(pos, {name = "wool:yellow"})
		table.insert(tbl, pos)
	end
	pos = find_surface({x = pos2.x, y = pos2.y, z = pos2.z})
	if pos then
		minetest.set_node(pos, {name = "wool:yellow"})
		table.insert(tbl, pos)
	end
	pos = find_surface({x = pos2.x, y = pos2.y, z = pos1.z})
	if pos then
		minetest.set_node(pos, {name = "wool:yellow"})
		table.insert(tbl, pos)
	end
	pos = find_surface({x = pos1.x, y = pos2.y, z = pos2.z})
	if pos then
		minetest.set_node(pos, {name = "wool:yellow"})
		table.insert(tbl, pos)
	end
	return tbl
end

-- Iterator over the four-section Y stack and an X/Z selection.
--     @dimension - X/Z selection: <1/2/3/5>
--                  (1=only this XZ column, 2=2x2 XZ, 3=3x3 XZ, 5=5x5 XZ)
--                  Y is always 4 sections: -1, 0, +1, +2
--     @func(npos, caller, num, param)
--         @npos   - new position within section
--         @caller - chatcommand caller name
--         @num    - section number like 'S14W50U1'
--         @param  - further parameter
--         function returns true for success
--     @caller - chatcommand caller name
--     @param  - additional chatcommand parameter
function sections.for_all_positions(dimension, func, caller, param)
	local cnt = 0
	local visited_sections = {}
	local player = minetest.get_player_by_name(caller)
	if player then
		local pos = vector.round(player:get_pos())
		for npos in iter_xz_sections(pos, dimension) do
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
		return cnt, " "
	else
		return cnt, "s "
	end
end

function sections.mark_current_section(caller)
	local player = minetest.get_player_by_name(caller)
	if player then
		sections.unmark_sections(caller)
		local pos = vector.round(player:get_pos())
		local number = sections.section_num(pos)
		local pos1, pos2 = sections.section_corners(pos)
		sections.mark_section(caller, pos1, pos2, number)
		return number
	end
end
