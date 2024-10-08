# Sections

**Protection mod for areas with fixed 16x16x16 grid for server staff**

## Introduction

The Mod Sections is a protection mod to protect larger areas in a fixed 16x16x16 grid.
Examples are the spawn for and by moderators, or planned settlements for other players.

Sections are blocks of size 16x16x16. However, they are not identical to map blocks,
but are offset by 8 blocks. This means that section boundaries always go right through
a map block. The idea behind this is that e.g. many Techage facilities should be built
within a map block, so that there can be no partial failures if not all map blocks of a
facility are loaded.

With 4 Sections, **one** Mapblock can be protected for the facility with sufficient
margin for buildings, paths, etc.

![Building plot](https://github.com/joe7575/sections/blob/master/screenshot.png)

### Commands

All commands always refer to the section you are currently in.
However, the commands can also be applied to multiple sections.
An additional parameter must be specified for this:

- `1` means 1x1x1 blocks, i.e., exactly one block (this parameter is optional)
- `2` means 2x2x2 blocks, i.e., the block you are standing in and additionally
  one block in the 3 directions that are closer to the current position
  (up to 8 blocks in total)
- `3` means 3x3x3 blocks, i.e., the block you are standing in and additionally
  one block in all directions (up to 27 blocks in total)
- `5` means 5x5x5 blocks, i.e., the block you are standing in and additionally
  two blocks in all directions (up to 125 blocks in total)

Chat commands:

- `/section_info <1/2/3/5>` shows whether and for whom the section(s) is/are protected
- `/section_mark` marks the corners of the outer boundaries of all selected sectors
  with wool blocks (additional privileges required)
- `/section_protect <1/2/3/5>` protects the section(s) in your name (additional privileges required)
- `/section_change_owner <name> <1/2/3/5>` changes the owner of the section(s)
  (can only be done by the owner of the section or a player with additional privileges)
- `/section_add_player <name> <1/2/3/5>` adds another player to the section(s)
  (can only be done by the owner of the section or a player with additional privileges)
- `/section_delete_player <name> <1/2/3/5>` removes a player from the section(s)
  (can only be done by the owner of the section or a player with additional privileges)
- `/section_delete <1/2/3/5>` deletes the section(s) (can only be done by the owner
  of the section or a player with additional privileges)

### Admin/Staff Privileges

To be able to protect and delete sections, the player must have additional privileges (privs).
Which additional privs are used can be configured. See 'settingtypes.txt'.
By default, the 'sections' priv is used. But you can also use any other available priv.  

### Admin Protection Tool

The Admin Protection Tool is a tool that allows you to convert protection blocks
from the 'protector' mod to sections and to show protection blocks around you.
You need the 'sections' priv to use this tool.

- to convert a protection block to a section, left-click with the tool
  on the protection block
- to show protection blocks around you, right-click with the tool in your hand

## License

Copyright (C) 2019-2024 Joachim Stolberg

Code: Licensed under the GNU AGPL version 3 or later. See LICENSE.txt

Textures: CC BY-SA 3.0

## History

- v1.00 (2024-09-15) * First release
