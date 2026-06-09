# Sections

**Protection mod for areas with a fixed 16x16x16 grid**

## Introduction

The Mod Sections is a protection mod to protect larger areas in a fixed 16x16x16 grid.
Examples are the spawn for and by moderators, or planned settlements for other players.

Sections are blocks of size 16x16x16. By default the grid is aligned to the
world origin (offset 0). Optionally the grid can be offset by 8 blocks
(configurable via the `sections_grid_offset` setting), so that section
boundaries run right through the middle of map blocks. 

The idea behind this is that, for example, many Techage facilities should be built
precisely within a single map block.
The 8-block border provides sufficient distance to neighboring buildings for a hall
or shell around the facility.

### Interaction with the `protector` mod

If the `protector` mod by TenPlus1 is loaded (declared as
`optional_depends` in `mod.conf`), the two protection systems cooperate:

- Build permission is the **OR** of section and protector checks. A player
  is blocked if either system says so. This means a Protector block
  inside a section owned by someone else does **not** open that section —
  it only protects the Protector block's own sub-area.
- The HUD only shows `Owner: ... [Section]`. Protector block owners are
  shown by the protector mod's own HUD (via `protector_hud_interval`).
- Migrating from the older "Protector Redux" (sorcerykid): that mod
  defines a `protector:protect3` node that the TenPlus1 version does not.
  Such blocks will appear as unknown nodes after the switch and can be
  removed with the bundled `remove_unknown` mod.

### Commands

All section commands always operate on the four sections -1, 0, +1, +2
in the Y direction relative to the section you are standing in. The
Section Protection Tool uses the same convention.

Player commands (require `interact`):

- `/section_change_owner <name>` changes the owner of your section(s)
- `/section_add_player <name>` adds another player to your section(s)
- `/section_delete_player <name>` removes a player from your section(s)
- `/section_delete` deletes your section(s)

The player commands can only be used on sections that are owned by the
caller (or by a player with the additional `sections` priv, see below).

Admin commands (require the additional `sections` priv):

The admin commands accept an optional X/Z parameter that defaults to `1`
if omitted:

- `1` means 1 section in X/Z (the section you are standing in)
- `2` means a 2x2 layout in X/Z (up to 4 sections in X/Z)
- `3` means a 3x3 layout in X/Z (up to 9 sections in X/Z)
- `5` means a 5x5 layout in X/Z (up to 25 sections in X/Z)

Combined with the 4 sections in Y this means each admin command operates
on 4, 16, 36, or 100 sections in total.

- `/section_mark [1/2/3/5]` marks the corners of the outer boundaries of all selected sectors
  with wool blocks
- `/section_protect [1/2/3/5]` protects the section(s) in your name

### Admin/Staff Privileges

To be able to use the admin chat commands (protect, delete, etc.) the player
must have additional privileges (privs). Which additional privs are used can
be configured. See 'settingtypes.txt'.
By default, the 'sections' priv is used. But you can also use any other available priv.  

### Protection HUD

While a player is standing inside a protected section, a small text is shown
in the top-right corner of the screen, e.g.:

```
Owner: Steve [Section]
```

`protector:protect*` block owners are shown by the `protector` mod's own
HUD (if enabled via `protector_hud_interval`) — `sections` does not
duplicate that display. The HUD is updated every 5 seconds. It is not
shown when the player is not inside a protected section.

### Section Protection Tool

The Section Protection Tool is a craftable item that lets any player with the
`interact` privilege inspect and claim sections. The tool always works on the
four sections around a block in the Y direction (+2, +1, 0, -1).

- **Left click / punch on a block** shows the owner of the four sections:
  ```
  +2: Ownername
  +1: Ownername
   0: Ownername
  -1: no protection
  ```
  (`no protection` is shown for unprotected sections)
- **Right click / place on a block** protects those four sections (the ones
  that are not yet protected) in the player's name and shows a marker around
  each protected section for 60 seconds. The cost is
  `sections_tool_cost_count` items of `sections_tool_cost_item` (default:
  4 diamonds) per use, taken from the player's main inventory. Sections that
  are already protected (by you or by someone else) are left untouched. If
  one of the four sections is protected by another player, no section is
  protected and a chat message is shown. If the player does not carry enough
  items, nothing is changed and a chat message is shown.

This replaces the previous `/section` and `/section_info` chat commands.

## Translations

User-visible strings (chat messages, command descriptions, tool
description) are wrapped with `S(...)` and look up translations from
`locale/<lang>.tr`. A German translation is provided in
`locale/sections.de.tr`.

To update the translation template after changing source strings, run
`python3 i18n.py` in the mod folder. To add a new language, create a
new `<lang>.tr` file in `locale/` based on `template.txt`.

## License

Copyright (C) 2019-2026 Joachim Stolberg

Code: Licensed under the GNU AGPL version 3 or later. See LICENSE.txt

Textures: CC BY-SA 3.0

## History

- v2.00 (2026-06-09) * Player mod: Tools instead of admin commands, Y=4 sections fixed
- v1.00 (2024-09-15) * First release
