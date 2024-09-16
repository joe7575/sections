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

sections = {}
sections.admin_privs = minetest.settings:get("sections_admin_privs") or "sections"
if sections.admin_privs == "sections" then
	minetest.register_privilege("sections")
end

dofile(minetest.get_modpath("sections") .. "/mark.lua")
dofile(minetest.get_modpath("sections") .. "/lib.lua")
dofile(minetest.get_modpath("sections") .. "/protection.lua")
dofile(minetest.get_modpath("sections") .. "/tool.lua")
