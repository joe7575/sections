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

local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local ForeignProtectionNodes = {
	["protector:protect"] = true, 
	["protector:protect2"] = true, 
	["protector:protect3"] = true,
	["protector:protect_hidden"] = true,
	["protector:protect3"] = true
}

local function get_keys(t)
	local keys = {}
	for key,_ in pairs(t) do
	  table.insert(keys, key)
	end
	return keys
  end

local function add_to_inventory_or_drop(pos, item, placer)
  local inv = placer:get_inventory()
  local leftover = inv:add_item("main", item) 
  if leftover:get_count() > 0 then
	  minetest.add_item(pos, leftover)
  end
end

local function protect_section(itemstack, placer, pointed_thing)
	local name = placer:get_player_name()
	if name and minetest.check_player_privs(name, sections.admin_privs) then
		if pointed_thing.type == "node" then
			local pos = pointed_thing.under
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)
			if ForeignProtectionNodes[node.name] then
				local owner = meta:get_string("owner")
				local members = meta:get_string("members")
				local names = {}
				if members ~= "" then
					for _,s in ipairs(string.split(members, " ")) do
						names[s] = true
					end
				end
				sections.protect_section(owner, "1", names)
				minetest.remove_node(pos)
				add_to_inventory_or_drop(pos, {name = node.name}, placer)
				minetest.chat_send_player(name, "Section is protection by " .. owner)
				return
			else
				minetest.chat_send_player(name, "This is no protection block!")
			end
		end
	else
		minetest.chat_send_player(placer:get_player_name(), 
			"You don't have the necessary privs!")
	end
end

local function show_protection_blocks(itemstack, placer, pointed_thing)
	local pos = placer:get_pos()
	local pos1 = {x = pos.x - 20, y = pos.y - 20, z = pos.z - 20}
	local pos2 = {x = pos.x + 20, y = pos.y + 20, z = pos.z + 20}
	local names = get_keys(ForeignProtectionNodes)
	local cnt = 0
	local name = placer:get_player_name()
	for _, pos3 in ipairs(minetest.find_nodes_in_area(pos1, pos2, names)) do
		sections.mark_node(name, pos3, "protect", "#FFFFFF", 10)
		cnt = cnt + 1
	end
	minetest.chat_send_player(name, cnt .. " protection blocks found")
end

local function do_nothing(itemstack, placer, pointed_thing)
end
	
-- Tool to convert protection blocks to sections
-- and to show protection blocks around you
minetest.register_node("sections:tool", {
	description = "Admin Protection Tool (left/use = convert protection" ..
		" block to section,\nright/place = show protection blocks around you)",
	inventory_image = "sections_tool.png",
	wield_image = "sections_tool.png",
	liquids_pointable = true,
	use_texture_alpha = true,
	groups = {cracky=1, book=1},
	on_use = protect_section,
	on_place = do_nothing,
	on_secondary_use = show_protection_blocks,
	node_placement_prediction = "",
	stack_max = 1,
})

-- Tool recipe
minetest.register_craft({
	output = "sections:tool",
	recipe = {
		{"", "", ""},
		{"", "default:diamond", ""},
		{"default:sword_wood", "", ""},
	}
})
