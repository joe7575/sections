local hud_idx = {}
local hud_timer = 0

local function section_num(pos)
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

local function innersection_num(pos)
	local xpos = math.floor((pos.x % 32) / 8)
	local zpos = math.floor((pos.z % 32) / 8)
	return xpos*10 + zpos
end

local function section_area(pos)
	local xpos = (math.floor(pos.x / 32) * 32)
	local zpos = (math.floor(pos.z / 32) * 32)
	local pos1 = {x = xpos, y = pos.y - 16, z = zpos}
	local pos2 = {x = xpos + 31, y = pos.y + 16, z = zpos + 31}
	return pos1, pos2
end

local function hud_text(pos)
	return {
		hud_elem_type = "text",
		position = {x = 1, y = 1},
		offset = {x = -100, y = -20},
		text = section_num(pos),
		number = 0xFFFFFF,
		scale = {x = 1, y = 1},
		alignment = { x = 1, y = 0},
	}
end

minetest.register_chatcommand("section", {
	params = "",
	description = "Sektion anzeigen",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.round(player:get_pos())
			local number = section_num(pos)
			local pos1, pos2 = section_area(pos)
			myspawn.mark_region(name, pos1, pos2, number)
			hud_idx[name] = player:hud_add(hud_text(pos))
		end
	end,
})


minetest.register_globalstep(function(dtime)

	-- every 2 seconds
	hud_timer = hud_timer + dtime
	if hud_timer < 2 then
		return
	end
	hud_timer = 0

	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		if hud_idx[name] then
			local pos = vector.round(player:get_pos())
			local section = section_num(pos)
			player:hud_change(hud_idx[name], "text", section_num(pos)..
				" / "..innersection_num(pos))
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	hud_idx[player:get_player_name()] = nil
end)


local old_is_protected = minetest.is_protected

minetest.register_privilege("starter", 
	{description = "Limitating privs for beginners", 
	give_to_singleplayer = false})


-- check for protected area, return true if protected
function minetest.is_protected(pos, digger)
	digger = digger or "" -- nil check

	if minetest.check_player_privs(digger, "starter") then
		-- Starter Area, everything else is protected for beginners (starter privs)
		if pos.x < 160 or pos.x > 760 or pos.z < 1650 or pos.z > 2280 then
			minetest.chat_send_player(digger, "You are outside of the starter area.")
			return true
		end
	end
	return old_is_protected(pos, digger)
end

minetest.register_chatcommand("normal", {
    privs = {
       superminer = true
    },
    func = function(name, param)
		local player = minetest.get_player_by_name(param)
		if player then
			local privs = minetest.get_player_privs(param)
			privs.starter = nil
			minetest.set_player_privs(param, privs)
			return true, "Der Spieler "..param.." wurde auf 'normal' gesetzt."
		end
		return false, "Den Spieler "..param.." gibt es nicht."
    end
})

minetest.register_chatcommand("starter", {
    privs = {
        superminer = true
    },
    func = function(name, param)
		local player = minetest.get_player_by_name(param)
		if player then
			local privs = minetest.get_player_privs(param)
			privs.starter = true
			minetest.set_player_privs(param, privs)
			return true, "Der Spieler "..param.." wurde auf 'starter' gesetzt."
		end
		return false, "Den Spieler "..param.." gibt es nicht."
    end
})

print("[myspawn] Mod loaded")