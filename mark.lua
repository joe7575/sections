--[[

	Sections
	========

	Copyright (C) 2020 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
]]--

local marker_region = {}

function sections.unmark_regions(name)
	if marker_region[name] ~= nil then --marker already exists
		--wip: make the area stay loaded somehow
		for _, entity in ipairs(marker_region[name]) do
			entity:remove()
		end
		marker_region[name] = nil
	end
end

-- name ist der Name des Spielers
function sections.mark_region(name, pos1, pos2, infotext)

	--sections.unmark_region(name)
	
	local sizex, sizey, sizez = (1 + pos2.x - pos1.x) / 2, (1 + pos2.y - pos1.y) / 2, (1 + pos2.z - pos1.z) / 2
	local markers = {}

	--XY plane markers
	for _, z in ipairs({pos1.z - 0.5, pos2.z + 0.5}) do
		local marker = minetest.add_entity({x=pos1.x + sizex - 0.5, y=pos1.y + sizey - 0.5, z=z}, "sections:region_cube")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x=sizex * 2, y=sizey * 2},
				collisionbox = {0,0,0, 0,0,0},
			})
			if infotext then
				marker:set_nametag_attributes({text = infotext})
			end
			marker:get_luaentity().player_name = name
			table.insert(markers, marker)
		end
	end

	--YZ plane markers
	for _, x in ipairs({pos1.x - 0.5, pos2.x + 0.5}) do
		local marker = minetest.add_entity({x=x, y=pos1.y + sizey - 0.5, z=pos1.z + sizez - 0.5}, "sections:region_cube")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x=sizez * 2, y=sizey * 2},
				collisionbox = {0,0,0, 0,0,0},
			})
			marker:set_yaw(math.pi / 2)
			marker:get_luaentity().player_name = name
			table.insert(markers, marker)
		end
	end

	marker_region[name] = markers
end

function sections.switch_region(name, pos1, pos2)
	if marker_region[name] ~= nil then --marker already exists
		sections.unmark_region(name)
	else
		sections.mark_region(name, pos1, pos2)
	end
end

minetest.register_entity(":sections:region_cube", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"sections_cube_mark.png"},
		--use_texture_alpha = true,
		physical = false,
		glow = 15,
		collide_with_objects = false,
		pointable = false,
		static_save = false,	
	},
	on_step = function(self, dtime)
		self.ttl = self.ttl or 60
		self.ttl = self.ttl - dtime
		if self.ttl <= 0 then
			self.object:remove()
		end
	end,
})

