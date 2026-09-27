# Tin Tower roof tiles: template and key

The rebuilt Tin Tower roof draws its roof slopes, ridges, railing, spire and
ladder from 26 tile slots in `gfx/tilesets/tower.png`. To replace them, edit
the template and apply it; the map, blocks and collision stay the same.

Only use art you have the rights to use.

| File | What it is |
|---|---|
| [`tin_tower_roof/roof_tiles_template.png`](tin_tower_roof/roof_tiles_template.png) | **The file you edit.** 128 × 24 pixels: the three rows of roof slots, at 1×, as they are now. |
| [`tin_tower_roof/roof_tiles_reference.png`](tin_tower_roof/roof_tiles_reference.png) | Every slot enlarged and labeled, in its daytime colors. |
| [`tin_tower_roof/roof_layout_reference.png`](tin_tower_roof/roof_layout_reference.png) | The whole roof, with the slot number drawn on every tile that uses a roof slot. |
| `tools/apply_roof_tiles.py` | Copies the template into `gfx/tilesets/tower.png`. |


## Workflow

1. Edit `docs/tin_tower_roof/roof_tiles_template.png` in any pixel editor.
2. Apply it and rebuild:

   ```
   python3 tools/apply_roof_tiles.py
   make && make crystal_hooh_debug
   ```

   The script checks the template's size and shades, and copies it into rows
   6–8 of `gfx/tilesets/tower.png`, leaving the rest of the tileset alone.
3. Look at it in game: the debug ROM starts next to the roof (see
   [`ho_oh_event.md`](ho_oh_event.md#the-debug-rom)).

Keep the template at **exactly 128 × 24 pixels**. You can save it in any PNG
format, as long as every pixel is one of four grays.


## Format

- Each slot is an **8 × 8 tile**. The template is 16 slots across and 3 down.
- Use **4 shades of gray**. The game recolors them with the tile's palette,
  and the palette changes with the time of day:

  | Shade | Hex | Palette color |
  |---|---|---|
  | white | `#FFFFFF` | 0 (lightest) |
  | light gray | `#AAAAAA` | 1 |
  | dark gray | `#555555` | 2 |
  | black | `#000000` | 3 (darkest) |

- Each tile uses **one palette**. The current palettes are **brown** (row 1),
  **gray** (row 2), and **green** (the first four tiles of row 3).
- To give a tile a different palette, change its entry in
  `gfx/tilesets/tower_palette_map.asm`. The first five `tilepal 1, …` lines
  cover the slots in order, 8 per line: line 1 is `$80`–`$87`, line 2 is
  `$88`–`$8f`, and so on. The palettes available are `GRAY`, `RED`, `GREEN`,
  `WATER`, `YELLOW`, `BROWN` and `ROOF`.

Daytime colors of the palettes the roof uses (Game Boy Color values):

| Palette | Color 0 | Color 1 | Color 2 | Color 3 |
|---|---|---|---|---|
| BROWN | 27,31,27 | 24,18,07 | 20,15,03 | 07,07,07 |
| GRAY | 27,31,27 | 21,21,21 | 13,13,13 | 07,07,07 |
| GREEN | 22,31,10 | 12,25,01 | 05,14,00 | 07,07,07 |


## Slot key

"x, y" is the slot's top-left pixel in the template. Slots `$xx` are tile
numbers in the game (VRAM bank 1).

### Row 1 (y = 0): roof and spire, brown

| Slot | x | Tile | Where it's used |
|---|---|---|---|
| `$80` | 0 | Roof, front/back slope | Everywhere above and below the platform, between the ridges. Tiles with itself in every direction. |
| `$81` | 8 | Roof, side slopes | Left and right of the platform. Tiles with itself in every direction. |
| `$82` | 16 | Ridge `\`, lower right | The hip running down-right from the platform's bottom-right corner. Side slope above-right, front slope below-left. |
| `$83` | 24 | Ridge `\`, upper left | The hip running up-left from the top-left corner. Back slope above-right, side slope below-left. |
| `$84` | 32 | Ridge `/`, lower left | The hip running down-left from the bottom-left corner. Side slope above-left, front slope below-right. |
| `$85` | 40 | Ridge `/`, upper right | The hip running up-right from the top-right corner. Back slope above-left, side slope below-right. |
| `$86` `$87` | 48, 56 | Spire, top half (left, right) | Each 16 × 16 spire segment: the top two tiles. |
| `$88` `$89` | 64, 72 | Spire, bottom half (left, right) | The bottom two tiles of each segment. Segments stack from the top of the map down to the base. |
| `$8a`–`$8f` | 80–120 | Spare | |

The ridge tiles repeat along a diagonal, so a line should leave each tile at
the corner where the next one picks it up.

### Row 2 (y = 8): railing and spire base, gray

| Slot | x | Tile | Where it's used |
|---|---|---|---|
| `$90` | 0 | Railing, horizontal | Top railing (roof above, floor below) and bottom railing (floor above, roof below). |
| `$91` | 8 | Railing, vertical | Left and right railings. |
| `$92` | 16 | Railing corner, top left | |
| `$93` | 24 | Railing corner, top right | |
| `$94` | 32 | Railing corner, bottom left | |
| `$95` | 40 | Railing corner, bottom right | |
| `$96` | 48 | Railing end, right of the gap | Just right of the ladder; its left end faces the gap. |
| `$97` | 56 | Railing end, left of the gap | Just left of the ladder; its right end faces the gap. |
| `$98` `$99` | 64, 72 | Spire base, top (left, right) | The pedestal under the spire, a 16 × 16 square. |
| `$9a` `$9b` | 80, 88 | Spire base, bottom (left, right) | |
| `$9c`–`$9f` | 96–120 | Spare | |

Each railing tile fills the half of a square nearest the floor. Its other
half is a roof tile.

### Row 3 (y = 16): ladder, green

| Slot | x | Tile | Where it's used |
|---|---|---|---|
| `$a0` `$a1` | 0, 8 | Ladder (left, right half) | From the gap in the railing down the roof slope; repeats vertically. |
| `$a2` `$a3` | 16, 24 | Hatch (left, right half) | The bottom of the ladder, where it leads down into the tower. |
| `$a4`–`$af` | 32–120 | Spare | |


## Not in the template

- **Floor:** the platform floor is the shared Tin Tower floor tile (tile `$02`,
  at row 0, x = 16 of `gfx/tilesets/tower.png`). Changing it changes every Tin
  Tower floor.
- **Overhead parts:** the dark area below the roof's edge, and anything drawn
  as a sprite (Ho-Oh, the kimono girls, the player).

For any of these, or if your art needs more tiles than the slots above (a
roof-only floor, more shingle variants, a two-tile railing), draw them in
the spare slots and describe where they go. The roof's blocks can then be
rebuilt to use them.
