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

local COST_ITEM = minetest.settings:get("sections_tool_cost_item") or "default:diamond"
local COST_COUNT = tonumber(minetest.settings:get("sections_tool_cost_count")) or 4
local S = sections.S

-- Returns the 4 section positions (+2, +1, 0, -1) in Y direction for the
-- section that contains the given node position.
local function get_section_positions(pos)
	local center = sections.section_center(pos)
	local y_step = 16
	return {
		{x = center.x, y = center.y + 2 * y_step, z = center.z}, -- +2
		{x = center.x, y = center.y + 1 * y_step, z = center.z}, -- +1
		{x = center.x, y = center.y,                z = center.z}, --  0
		{x = center.x, y = center.y - 1 * y_step, z = center.z}, -- -1
	}
end

local function owner_of(pos)
	local num = sections.section_num(pos)
	local items = sections.ProtectedSections[num]
	if not items then
		return nil
	end
	return items.owner or sections.admin_privs
end

-- Left click / "use" (punch)
local function on_punch(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return
	end
	local name = placer:get_player_name()
	if not minetest.check_player_privs(name, "interact") then
		minetest.chat_send_player(name, S("You don't have the necessary privs!"))
		return
	end
	local positions = get_section_positions(pointed_thing.under)
	local labels = {"+2", "+1", " 0", "-1"}
	for i, p in ipairs(positions) do
		local owner = owner_of(p)
		local text
		if owner then
			text = S("@1: @2", labels[i], owner)
		else
			text = S("@1: no protection", labels[i])
		end
		minetest.chat_send_player(name, text)
	end
	local pos1, pos2 = sections.section_corners(positions[3])
	sections.unmark_sections(name)
	sections.mark_section(name, pos1, pos2, S("Section @1", sections.section_num(positions[3])))
end

-- Right click / "place" -> protect up to 4 sections for the player
local function on_place(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return
	end
	local name = placer:get_player_name()
	if not minetest.check_player_privs(name, "interact") then
		minetest.chat_send_player(name, S("You don't have the necessary privs!"))
		return
	end
	local positions = get_section_positions(pointed_thing.under)
	local to_protect = {}
	local blocked_by = nil
	for _, p in ipairs(positions) do
		local owner = owner_of(p)
		if not owner then
			to_protect[#to_protect + 1] = p
		elseif owner ~= name then
			blocked_by = owner
		end
	end
	if blocked_by then
		minetest.chat_send_player(name, S("Section already protected by @1!", blocked_by))
		return
	end
	if #to_protect == 0 then
		minetest.chat_send_player(name, S("All 4 sections are already protected!"))
		return
	end
	-- Take the cost. Only remove items when we actually have enough and only
	-- as many as needed.
	local inv = placer:get_inventory()
	local total = 0
	for i = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		if stack:get_name() == COST_ITEM then
			total = total + stack:get_count()
		end
	end
	if total < COST_COUNT then
		minetest.chat_send_player(name, S("Not enough @1 (need @2)!", COST_ITEM, tostring(COST_COUNT)))
		return
	end
	inv:remove_item("main", {name = COST_ITEM, count = COST_COUNT})

	sections.unmark_sections(name)
	for _, p in ipairs(to_protect) do
		local num = sections.section_num(p)
		sections.ProtectedSections[num] = {owner = name, names = {}}
		local pos1, pos2 = sections.section_corners(p)
		sections.mark_section(name, pos1, pos2, num)
	end
	sections.save()
	minetest.chat_send_player(name, S("@1 section(s) protected for @2", tostring(#to_protect), name))
end

minetest.register_node("sections:tool", {
	description = S("Section Protection Tool") .. "\n" ..
		S("left/punch = show owner of the 4 sections around the block (+2/+1/0/-1)") .. "\n" ..
		S("right/place = protect those 4 sections for you (costs @1x @2)", tostring(COST_COUNT), COST_ITEM),
	inventory_image = "sections_tool.png",
	wield_image = "sections_tool.png",
	liquids_pointable = true,
	use_texture_alpha = true,
	groups = {cracky = 1, book = 1},
	on_use = on_punch,
	on_place = on_place,
	on_secondary_use = on_place,
	node_placement_prediction = "",
	stack_max = 1,
})

minetest.register_craft({
	output = "sections:tool",
	recipe = {
		{"", "", ""},
		{"", "default:diamond", ""},
		{"default:sword_wood", "", ""},
	}
})
