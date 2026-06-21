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

### Commands

The Section Protection Tool always affects the four sections stacked
vertically at the X/Z position of the clicked block (levels -1, 0, +1, +2
in Y). The player-management chat commands act on the single section the
player is currently standing in.

Player commands (require `interact`). All section-management commands act
**on the single section the player is currently standing in** (level 0 in Y),
not the four-section Y stack:

- `/section_change_owner <name>` changes the owner of your section
- `/section_add_player <name>` adds another player to your section
- `/section_remove_player <name>` removes a player from your section
  (alias: `/section_delete_player`, kept for backwards compatibility)
- `/section_delete` releases the four-section Y stack (the same area the
  tool claims). The protection cost
  (`sections_tool_cost_count` × `sections_tool_cost_item`) is refunded to
  the caller

The player commands can only be used on sections that are owned by the
caller (or by a player with the additional `sections` priv, see below).

To inspect a section (owner + members), use the Section Protection Tool
(left-click a block). It shows the four-section Y stack around the
target block as e.g. `+1: owner (member1, member2)`.

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
`interact` privilege inspect and claim sections. When you click a block, the
tool affects the four sections stacked vertically at that block's X/Z
position: the section containing the block (level 0), the section below
(level -1), and the two sections above (levels +1, +2). All four sections
share the same X/Z position; they only differ in their Y level.

- **Left click / punch on a block** shows the owner (and member list) of
  the four sections:
  ```
  +2: Ownername
  +1: Ownername (member1, member2)
   0: no protection
  -1: Ownername
  ```
  (`no protection` is shown for unprotected sections; members are listed
  in parentheses after the owner)
- **Right click / place on a block** protects those four sections (the ones
  that are not yet protected) in the player's name and shows a marker around
  each protected section for 60 seconds. The cost is
  `sections_tool_cost_count` items of `sections_tool_cost_item` (default:
  4 diamonds) per use, taken from the player's main inventory. Sections that
  are already protected (by you or by someone else) are left untouched. If
  one of the four sections is protected by another player, no section is
  protected and a chat message is shown. If the player does not carry enough
  items, nothing is changed and a chat message is shown.

This replaces the previous `/section` chat command. The former
`/section_info` command has been removed because the tool now shows the
same information (owner + members) directly.

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

- v2.01 (2026-06-21) * Tool now shows owner and members; section
  management commands act on the single current section (not the Y
  stack); refunded protection cost on `/section_delete`,
  renamed `/section_delete_player` to `/section_remove_player`
  (old name kept as alias)
- v2.00 (2026-06-09) * Player mod: Tools instead of admin commands, Y=4 sections fixed
- v1.00 (2024-09-15) * First release
