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

local marker_region = {}

function sections.unmark_sections(name)
	if marker_region[name] ~= nil then --marker already exists
		for _, entity in ipairs(marker_region[name]) do
			entity:remove()
		end
		marker_region[name] = nil
	end
end

-- Name is the player/caller name
function sections.mark_section(name, pos1, pos2, infotext)
	local sizex, sizey, sizez = (1 + pos2.x - pos1.x) / 2, (1 + pos2.y - pos1.y) / 2, (1 + pos2.z - pos1.z) / 2
	local markers = marker_region[name] or {}

	--XY plane markers
	for _, z in ipairs({pos1.z - 0.5, pos2.z + 0.5}) do
		local marker = minetest.add_entity({x = pos1.x + sizex - 0.5, y = pos1.y + sizey - 0.5, z = z}, "sections:mark_section")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x = sizex * 2, y = sizey * 2},
				collisionbox = {0,0,0, 0,0,0},
			})
			marker:set_nametag_attributes({text = infotext})
			table.insert(markers, marker)
		end
	end

	--YZ plane markers
	for _, x in ipairs({pos1.x - 0.5, pos2.x + 0.5}) do
		local marker = minetest.add_entity({x = x, y = pos1.y + sizey - 0.5, z = pos1.z + sizez - 0.5}, "sections:mark_section")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x=sizez * 2, y=sizey * 2},
				collisionbox = {0,0,0, 0,0,0},
			})
			marker:set_nametag_attributes({text = infotext})
			marker:set_yaw(math.pi / 2)
			table.insert(markers, marker)
		end
	end

	marker_region[name] = markers
	minetest.after(60, sections.unmark_sections, name)
end

function sections.mark_node(name, pos, infotext)
	local marker = minetest.add_entity(pos, "sections:mark_node")
	if marker ~= nil then
		marker:set_nametag_attributes({text = infotext})
		marker:get_luaentity().player_name = name
		marker_region[name] = marker_region[name] or {}
		marker_region[name][#marker_region[name] + 1] = marker
	end
	minetest.after(60, sections.unmark_sections, name)
end

minetest.register_entity("sections:mark_section", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"sections_cube_mark.png"},
		physical = false,
		glow = 15,
		collide_with_objects = false,
		pointable = false,
		static_save = false,	
	},
})

minetest.register_entity("sections:mark_node", {
	initial_properties = {
		visual = "cube",
		textures = {
			"sections_cube_mark.png",
			"sections_cube_mark.png",
			"sections_cube_mark.png",
			"sections_cube_mark.png",
			"sections_cube_mark.png",
			"sections_cube_mark.png",
		},
		physical = false,
		visual_size = {x = 1.1, y = 1.1},
		collisionbox = {-0.55,-0.55,-0.55, 0.55,0.55,0.55},
		glow = 8,
		static_save = false,
	},
	on_punch = function(self)
		self.object:remove()
	end,
})
