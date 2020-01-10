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

function sections.grep(pos, days, name)
	local t = minetest.get_us_time()
	local tbl = {" ########### Start of Query ############"}
	local num = section_num(pos)
	local day = (os.date("%w") + 21 + tonumber(days)) % 7
	local fname = WPATH..DIR_DELIM.."player_actions_"..day..".txt"
	name = sections.pattern_escape(name)
	if file_exists(fname) then
		for line in io.lines(fname) do
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
	end
	t = minetest.get_us_time() - t
	t = string.format("%s", t/1000000)
	table.insert(tbl, (#tbl-1).." matches found in "..t.." seconds")
	return tbl
end
