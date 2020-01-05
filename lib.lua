local WPATH = minetest.get_worldpath()

function sections.section_num(pos)
	local xpos = math.floor(pos.x / 32)
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
	return zpos..xpos
end

function sections.innersection_num(pos)
	local xpos = math.floor((pos.x % 32) / 8)
	local zpos = math.floor((pos.z % 32) / 8)
	return xpos*10 + zpos
end

function sections.section_area(pos)
	local xpos = (math.floor(pos.x / 32) * 32)
	local zpos = (math.floor(pos.z / 32) * 32)
	local pos1 = {x = xpos, y = pos.y - 16, z = zpos}
	local pos2 = {x = xpos + 31, y = pos.y + 16, z = zpos + 31}
	return pos1, pos2
end

local innersection_num = sections.innersection_num
local section_num = sections.section_num
local section_area = sections.section_area

function sections.logging(pos, name, action, item)
	local f = io.open(WPATH..DIR_DELIM.."player_actions.txt", "a+")
	local num = section_num(pos)
	local spos = minetest.pos_to_string(pos)
	f:write (num..": "..name.." "..action.." '"..item.name.."' on "..spos.." at '"..os.date(), "'\n")
	f:close()
end

function sections.grep(pos, name)
	local tbl = {" ########### Start of Query ############"}
	local num = section_num(pos)
	for line in io.lines(WPATH..DIR_DELIM.."player_actions.txt") do
		local parts = string.split(line, ":", false, 1)
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
	table.insert(tbl, (#tbl-1).." matches found.")
	return tbl
end
