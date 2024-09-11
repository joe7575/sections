--[[

	Sections
	========

	Copyright (C) 2020-2024 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--
local WPATH = minetest.get_worldpath()

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

function sections.iter_sections(pos, dimension)
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

function sections.section_pos(num)
	local _, _, z, zpos, x, xpos, y, ypos = string.find(num, "(%u)(%d+)(%u)(%d+)(%u)(%d+)")
	xpos = ((xpos * 16) - 8) * (x == "E" and -1 or 1)
	ypos = ((ypos * 16) - 8) * (y == "D" and -1 or 1)
	zpos = ((zpos * 16) - 8) * (z == "S" and -1 or 1)
	return {x = xpos, y = ypos, z = zpos}
end

function sections.section_area(pos)
	local xpos = (math.floor((pos.x + 8) / 16) * 16) - 8
	local ypos = (math.floor((pos.y + 8) / 16) * 16) - 8
	local zpos = (math.floor((pos.z + 8) / 16) * 16) - 8
	local pos1 = {x = xpos, y = ypos, z = zpos}
	local pos2 = {x = xpos + 15, y = ypos + 15, z = zpos + 15}
	return pos1, pos2
end

local section_num = sections.section_num

function sections.pattern_escape(text)
	if text ~= nil then
		text = string.gsub(text, "%(", "%%(")
		text = string.gsub(text, "%)", "%%)")
		text = string.gsub(text, "%.", "%%.")
		text = string.gsub(text, "%*", "%%*")
		text = string.gsub(text, "%+", "%%+")
		text = string.gsub(text, "%-", "%%-")
		text = string.gsub(text, "%[", "%%[")
		text = string.gsub(text, "%?", "%%?")
	end
	return text
end

local function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

function sections.logging(pos, name, action, item)
	local day = os.date("%w")
	local fname = WPATH..DIR_DELIM.."player_actions_"..day..".txt"
	local f = io.open(fname, "a+")
	local num = section_num(pos)
	local spos = minetest.pos_to_string(pos)
	f:write (num..": "..name.." "..action.." '"..item.name.."' on "..spos.." at '"..os.date(), "'\n")
	f:close()
end

-- see https://www.lua.org/pil/21.2.1.html
function sections.grep(pos, name)
	local t = minetest.get_us_time()
	local tbl = {" ########### Start of Query ############"}
	local num = section_num(pos)
	local fname = WPATH..DIR_DELIM.."action.txt"
	local BUFSIZE = 2^13     -- 8K
	name = sections.pattern_escape(name)
	if file_exists(fname) then
		local f = io.input(fname)
		while true do
			local lines, rest = f:read(BUFSIZE, "*line")
			if not lines then break end
			if rest then lines = lines .. rest .. '\n' end
			for _,line in ipairs(string.split(lines, "\n")) do
				local parts = string.split(line, " ", false, 1)
				if parts[1] == num then
					if name == "" or string.find(parts[2], name) then
						table.insert(tbl, parts[2])
						if #tbl >= 100 then
							table.insert(tbl, "***************** max (100) reached *******************")
							return tbl
						end
					end
				end
			end
		end
	end
	t = minetest.get_us_time() - t
	t = string.format("%s", t/1000000)
	table.insert(tbl, (#tbl-1).." matches found in "..t.." seconds")
	return tbl
end

minetest.after(1, function()
	local day = os.date("%w")
	local fname = WPATH..DIR_DELIM.."player_actions_"..day..".txt"
	os.remove(fname)
end)
