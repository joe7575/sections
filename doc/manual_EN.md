# Player Manual

With the **Sections** mod you can protect large building areas in the world so
that nobody (except you and your friends) can dig or place blocks there. The
world is divided into **sections** of size 16×16×16.

## The Section Protection Tool

Hold the tool in your hand and look at any block. When you use the tool,
it affects the **four sections stacked vertically at the X/Z position of
that block**:

- the **section the block is in** (level 0)
- the **section below** it (level −1)
- the **section directly above** it (level +1)
- the **section two blocks above** it (level +2)

All four sections share the same X/Z position; they only differ in their
Y level. The section IDs are encoded by the mod as strings like
`N710W658U1` (North/South, West/East, Up/Down + index).

### Left click / punch on a block

Shows in the chat who owns the four sections around the block. Members
(additional players with access to the section) are listed in parentheses
after the owner, sorted alphabetically:

```
+2: PlayerName
+1: PlayerName (member1, member2)
 0: no protection
-1: PlayerName
```

Additionally, the middle section (level 0) is highlighted with a blue frame
for 60 seconds.

### Right click / place on a block

Claims the still-free sections of the four for you. On this server this costs
**3 gold ingots** from your inventory (mod default: 4 diamonds — the server admin
can change this). Sections that are already owned by someone are left
untouched. After claiming, the newly protected sections are highlighted with
blue frames for 60 seconds.

### What if I don't have enough gold?

Nothing happens and you get a chat message. No items are taken.

## Friends / Co-Owners

You can give other players rights to your sections (you must be the owner).
Each command acts on **the single section you are currently standing in**
(not the four-section Y stack):

- `/section_change_owner <Name>` — set a new owner (you will lose the protection)
- `/section_add_player <Name>` — add a player to the current section
- `/section_remove_player <Name>` — remove a player from the current section
- `/section_delete` — release the four sections (Y=-1..+2). The protection
  cost is **refunded** to you.

## HUD Display

While you are inside a protected section, a small text is shown in the
top-right corner of the screen:

```
Owner: PlayerName [Section]
```

## Exact block-by-block protection with the Protector mod

If you only want to protect a small area (e.g. a single machine, a chest or a
market stall) that does **not** fit into the 16×16×16 grid, use the
**Protector** mod:

- **Craft a protection block** (recipe varies by server setup — a common
  one is 3×3 of stone with a gold or silver ingot in the middle; the exact
  recipe is defined by the Protector mod)
- **Place it** — the block protects a cube of 5-block radius around it by
  default
- As the owner you can add members

> Note: A Protector block **inside** a protected section does **not** open
> that section. The two systems are independent.

## Where are the section borders?

Sections start at the world origin (coordinate 0/0/0) and extend in steps of 16:

- X: 0..15, 16..31, 32..47, …
- Y: -16..-1, 0..15, 16..31, …
- Z: 0..15, 16..31, 32..47, …

A section ID like `N710W658U1` means: North, X-axis 658, Up, Y-axis 1.
