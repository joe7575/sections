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
local Offsets222 = {}
local Offsets333 = {}
local Offsets555 = {}

for x = -8, 8, 8 do
	for y = -8, 8, 8 do
		for z = -8, 8, 8 do
			table.insert(Offsets222, {x = x, y = y, z = z})
		end
	end
end

for x = -16, 16, 16 do
	for y = -16, 16, 16 do
		for z = -16, 16, 16 do
			table.insert(Offsets333, {x = x, y = y, z = z})
		end
	end
end

for x = -32, 32, 16 do
	for y = -32, 32, 16 do
		for z = -32, 32, 16 do
			table.insert(Offsets555, {x = x, y = y, z = z})
		end
	end
end

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

local function iter_sections(pos, dimension)
	local i = 0
	if dimension == "2" then
		-- 2x2x2 = 8 section
		return function()
			i = i + 1
			local offs = Offsets222[i]
			if offs then
				return {x = pos.x + offs.x, y = pos.y + offs.y, z = pos.z + offs.z}
			end
		end
	elseif dimension == "3" then
		-- 3x3x3 = 27 section
		return function()
			i = i + 1
			local offs = Offsets333[i]
			if offs then
				return {x = pos.x + offs.x, y = pos.y + offs.y, z = pos.z + offs.z}
			end
		end
	elseif dimension == "5" then
		-- 5x5x5 = 125 sections
		return function()
			i = i + 1
			local offs = Offsets555[i]
			if offs then
				return {x = pos.x + offs.x, y = pos.y + offs.y, z = pos.z + offs.z}
		  end
		end
	else
		-- 1x1x1 = 1 section
		return function()
			i = i + 1
			if i == 1 then
				return pos
			end
		end
	end
end

-------------------------------------------------------------------------------
-- API functions
-------------------------------------------------------------------------------
function sections.section_num(pos)
	local xpos = math.floor((pos.x + 8) / 16)
	local ypos = math.floor((pos.y + 8) / 16)
	local zpos = math.floor((pos.z + 8) / 16)
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
	local xpos = (math.floor((pos.x + 8) / 16) * 16) - 8
	local ypos = (math.floor((pos.y + 8) / 16) * 16) - 8
	local zpos = (math.floor((pos.z + 8) / 16) * 16) - 8
	local pos1 = {x = xpos, y = ypos, z = zpos}
	local pos2 = {x = xpos + 15, y = ypos + 15, z = zpos + 15}
	return pos1, pos2
end

-- Place wool blocks in all 4 corners of the section area
function sections.place_markers(pos1, pos2)
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
function sections.for_all_positions(dimension, func, caller, param)
	local cnt = 0
	local visited_sections = {} 
	local player = minetest.get_player_by_name(caller)
	if player then
		local pos = vector.round(player:get_pos())
		for npos in iter_sections(pos, dimension) do
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
