--[[

	Sections
	========

	Copyright (C) 2020 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--
local WPATH = minetest.get_worldpath()

function sections.section_num(pos)
	local xpos = math.floor(pos.x / 32)
	local ypos = math.floor(pos.y / 32)
	local zpos = math.floor(pos.z / 32)
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
	return zpos..xpos.."V"..ypos
end

function sections.section_area(pos)
	local xpos = (math.floor(pos.x / 32) * 32)
	local ypos = (math.floor(pos.y / 32) * 32)
	local zpos = (math.floor(pos.z / 32) * 32)
	local pos1 = {x = xpos, y = ypos, z = zpos}
	local pos2 = {x = xpos + 31, y = ypos + 31, z = zpos + 31}
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
