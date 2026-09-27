# Tin Tower roof Ho-Oh event: editing guide

A reference for changing the Ho-Oh event on the `ho-oh-event` branch:
supplying the cutscene art, tweaking timing and choreography, rebuilding
the roof, and testing with the debug ROM.

- [What the event does](#what-the-event-does)
- [Where everything lives](#where-everything-lives)
- [Cutscene art](#cutscene-art)
- [Tweaking the cutscene](#tweaking-the-cutscene)
- [The kimono girls' dance](#the-kimono-girls-dance)
- [The rooftop map and tiles](#the-rooftop-map-and-tiles)
- [The debug ROM](#the-debug-rom)
- [Testing in an emulator](#testing-in-an-emulator)
- [Git: fork, branch and pushing](#git-fork-branch-and-pushing)
- [Limits and gotchas](#limits-and-gotchas)


## What the event does

With the Rainbow Wing, and before Ho-Oh has been fought:

1. The player climbs the ladder to the Tin Tower roof and stops in the gap in
   the railing, in front of five kimono girls.
2. The middle girl gives a welcome speech. A white flash, then the girls
   dance (about 12 seconds) to the Kimono Girl music, and a bell rings.
3. The screen fades to white and the sky cutscene plays (about 18 seconds).
4. The roof fades back in with the camera raised to the top of the spire.
   Ho-Oh comes down the spire as the camera pans back down to the player,
   and lands below the spire base. A flash, Ho-Oh cries, the girls speak,
   the middle girl steps aside, and the player walks up.
5. "Shaoooh!", a flash, and the battle starts.

On later visits the girls stand where the dance ended, and Ho-Oh is there
until it has been fought.


## Where everything lives

| What | File |
|---|---|
| Event script, dance lanes, dialogue, object positions | `maps/TinTowerRoof.asm` |
| Roof layout (blocks) | `maps/TinTowerRoof.blk` |
| Cutscene engine and its timing constants | `engine/events/ho_oh_descent.asm` |
| Cutscene art slots and their spec | `gfx/ho_oh_descent/` (see its `README.md`) |
| Sky, cloud, streak tiles; sparkle and leaf sprites | `gfx/overworld/ho_oh_descent_bg.png`, `ho_oh_descent_ob.png` |
| `special HoOhDescent` wrapper | `engine/events/specials.asm` |
| Group ("dance") movement engine | `engine/overworld/map_objects.asm` (`MovementFunction_Dance`, `GetDanceMovementIndex`) |
| Roof tiles, blocks, collision, palettes | `gfx/tilesets/tower.png`, `data/tilesets/tower_metatiles.bin`, `tower_collision.asm`, `gfx/tilesets/tower_palette_map.asm` |
| Kimono girl sprite on the roof | `data/maps/outdoor_sprites.asm` (`FastShipGroupSprites`) |
| Scene variable, event flag | `ram/wram.asm` (`wTinTowerRoofSceneID`), `constants/event_flags.asm` (`EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS`) |
| ROM bank placement | `layout.link` ("Ho-Oh Descent" in bank `$61`, "Ho-Oh Descent Graphics" in `$7f`, "Egg Moves" moved to `$60`) |
| Debug ROM start | `engine/menus/intro_menu.asm` (`HoOhEventDebugSetup`), `maps/TinTower9F.asm` |


## Cutscene art

The cutscene has three art slots. The files there now are geometric
placeholders (a sunburst, a chevron and a diamond). To use your own art,
replace the PNG and run `make`; the Makefile converts it with `rgbgfx`, and
the build fails with a message if a picture breaks a limit.

Only use art you have the rights to use.

### `gfx/ho_oh_descent/closeup.png`

- 128 × 96 pixels, full color.
- At most 4 colors per 8 × 8 tile, 7 palettes in total, 256 unique tiles.
- The sky palette is separate, so paint the background into the picture
  (the cutscene sky is Game Boy Color `15,23,31`, about `#7BBDFF`).
- Shown between the letterbox bars at screen x 32–159, y 24–119; it slides in
  from the right edge.

### `gfx/ho_oh_descent/silhouette.png`

- 64 pixels wide; frames 48 pixels tall, stacked top to bottom (1–5 frames,
  so the image is 48, 96, 144, … pixels tall).
- Transparent background (PNG alpha) plus at most 3 colors in total.
- Flies right to left with its top at screen y 38.

### `gfx/ho_oh_descent/diver.png`

- 64 pixels wide; frames 64 pixels tall, stacked top to bottom (1–4 frames).
- Transparent background, up to 4 palettes of 3 colors. Each 8 × 16 block
  (counted from each frame's top-left) must use a single palette.
- Frame 0 is used while it dives in; then it hovers with its top-left at
  screen (23, 42).

### What the build produces

`make` turns each PNG into files next to it; these are generated, so they
are git-ignored:

| Slot | Generated files |
|---|---|
| close-up | `closeup.2bpp`, `.tilemap`, `.attrmap`, `.palettes` |
| silhouette | `silhouette.2bpp`, `.palettes` |
| diver | `diver.2bpp`, `.attrmap`, `.palettes` |

If you only replace a PNG, `make` rebuilds everything that depends on it.


## Tweaking the cutscene

All in `engine/events/ho_oh_descent.asm`.

### Timing and speed

The constants at the top of the file; frames are 1/60 s.

| Constant | Default | Meaning |
|---|---|---|
| `HOOHDESCENT_WHITE_IN_FRAMES` | 96 | white before the sky |
| `HOOHDESCENT_SKY_FRAMES` | 176 | empty letterboxed sky |
| `HOOHDESCENT_CLOSEUP_SLIDE_SPEED` | 5 | close-up slide, pixels per frame |
| `HOOHDESCENT_CLOSEUP_HOLD_FRAMES` | 60 | close-up hold |
| `HOOHDESCENT_BLACK_FRAMES` | 30 | each black cut |
| `HOOHDESCENT_SILHOUETTE_SPEED` | 9 | silhouette speed, eighths of a pixel per frame |
| `HOOHDESCENT_CLOUDS_TAIL_FRAMES` | 110 | clouds after the silhouette leaves |
| `HOOHDESCENT_DIVE_SPEED` | 5 | dive speed, half pixels per frame |
| `HOOHDESCENT_HOVER_FRAMES` | 190 | hovering |
| `HOOHDESCENT_WHITE_OUT_FRAMES` | 132 | white at the end |
| `HOOHDESCENT_SPARKLE_LIFE` | 90 | how long each sparkle lasts |

Frame counts are single bytes, so keep each under 256.

### Positions

`HOOHDESCENT_SILHOUETTE_TOP`, `HOOHDESCENT_DIVER_LEFT`,
`HOOHDESCENT_DIVER_TOP` and `HOOHDESCENT_CLOUD_ROW` (the BG row where the
clouds begin).

### Animation

Two tables of `db frame, frames shown`, ending in `db -1`. The sequence
loops. A frame number past the picture's last frame shows its last frame.

```
HoOhDescentSilhouetteSequence:
	db 0, 45
	db 1, 15
	db -1

HoOhDescentDiverHoverSequence:
	db 0, 12
	db 1, 24
	db 0, 12
	db 2, 12
	db -1
```

### Colors

`HoOhDescentSkyPalette` and `HoOhDescentObjectPalettes` (sparkles, leaves).
The slot pictures bring their own palettes.

### Sound

The `PlaySFX` calls in `.SkyHold` (close-up), `.CloudsStart` (silhouette) and
`.DiveStart` (dive).

### How the shots are built

The close-up is drawn on the window layer, so it can slide in from the
right. The silhouette and diver are 8 × 16 sprites. During each black cut,
the next shot's map and tiles are copied into VRAM with HDMA while the
screen stays on, so the cut stays black instead of flashing white.


## The kimono girls' dance

The dance lives in `maps/TinTowerRoof.asm`:

- `TinTowerRoofKimonoGirlsDanceAsm` starts every girl's lane at once, using
  the `SPRITEMOVEDATA_DANCE` movement type added for this.
- `TinTowerRoofDanceLanes` holds one ordinary movement list per girl
  (`step`, `turn_in`, `turn_step`, `step_sleep`, …).

### Rules when editing lanes

- **Every lane must last the same number of frames.** The script continues
  when the first girl reaches `step_end`. Timings:
  - `step`: 8 frames
  - `turn_in` (spinning step): 8 frames
  - `turn_step`: about 4 frames
  - `step_sleep N`: N frames
  - `turn_head`: about 1 frame
- **No two girls may end a beat on the same square.** The engine doesn't
  check collisions for scripted movement.
- Keep girls off the spire column (x 9, y ≤ 5) and off the player's square
  (9, 8).
- **Final positions must match the callback.** Where the girls end must match
  the `moveobject` lines in `TinTowerRoofHoOhCallback` (used on later
  visits): (7,4), (7,7), (10,7), (11,7) and (11,4) after the middle girl
  steps aside.

### Positions

- Girls start in a row at y 7, x 7–11.
- The dance points are the corners (7,4), (11,4), (7,7), (11,7) and the
  centre (9,6), below the spire.
- Ho-Oh lands at (9,6).
- The player waits at (9,8) and walks up to (9,7).

### Regenerating the lanes

The lanes were generated by a script (`gen_dance2.py`, see
[Helper scripts](#helper-scripts)) that builds each figure, pads every lane to
the same length, and checks for collisions. Edit its figure tables and run it
to regenerate the `TinTowerRoofDanceLanes` block, rather than hand-editing
timings.


## The camera pan and Ho-Oh's descent

The game's camera always follows the player, so the pan after the cutscene
moves the player:

1. While the screen is white (before `special HoOhDescent`),
   `TinTowerRoofCameraRisesMovement` hides the player and moves them 3 squares
   up. `reanchormap` follows, because full-screen specials expect the BG map
   anchored at its top-left. Ho-Oh is then placed at (9,0) with `moveobject`
   and `appear`, above the view.
2. After the cutscene, `TinTowerRoofHoOhDescendsAsm` starts two lanes of
   `TinTowerRoofHoOhDescendsLanes` at once:
   - The hidden player walks back down to the gap; the camera follows it.
   - Ho-Oh `slow_step`s down to (9,6).
   Then the player reappears facing up.
3. `TinTowerRoofStartLanes` is the shared lane starter, also used by the
   dance. It takes a -1-terminated list of objects (`PLAYER` included) and a
   lanes table.

Scripted steps are at least 1 pixel per frame, so the pan takes about 0.8 s,
where the reference video takes about 1.5 s.

The `HoOhDescent` special clears `hBGMapMode` on its way out. Otherwise the
screen buffer keeps being copied to the BG map while the camera scrolls,
which corrupts the rows that scroll in.


## The rooftop map and tiles

- The roof is 10 × 9 blocks. The platform's floor is x 7–11, y 4–7 (in 16 ×
  16 squares), inside a grey railing. The spire runs down column 9 to its
  base at (9,5). A ladder runs from the gap at (9,8) to the warp at (9,13),
  which leads to Tin Tower 9F.
- New tiles are tower tiles `$80`–`$A3` in VRAM bank 1 (rows 6–8 of
  `gfx/tilesets/tower.png`). Their palettes are set in
  `tower_palette_map.asm`: brown roof and spire, grey railing and base, green
  ladder.
- New blocks are `$40`–`$56` (87 blocks total). Blocks above `$7f` don't load
  correctly (a known engine bug), so stay under 128.
- Everything was generated by `build_roof.py` (see
  [Helper scripts](#helper-scripts)), which draws the tiles, lays the roof out
  square by square, and writes the blocks, collision and map. Changing the
  roof means editing that script and re-running it.

### Why the kimono girls needed a fix

The roof counts as an outdoor map. Outdoor maps load their sprites from a
fixed per-map-group list, not from their objects. The roof is in the Fast
Ship map group, so `SPRITE_KIMONO_GIRL` replaced the unused
`SPRITE_GENTLEMAN` in `FastShipGroupSprites`. Any new sprite added to the roof
needs the same treatment.


## The debug ROM

```
make crystal_hooh_debug    # builds pokecrystal_hooh_debug.gbc
```

It's built with `-D _HO_OH_DEBUG`, not `_DEBUG`, because `_DEBUG` reads debug
switches from save RAM that can skip battles. **NEW GAME** skips the intro
and sets:

- **Location:** Tin Tower 9F at (5,3), facing down (the video's first frame).
- **Player:** a girl named KRIS.
- **Clock:** the first option of each prompt: 10:00 AM, Sunday, DST on.
- **Items:** the Rainbow Wing.
- **Party:** one level 43 Ampharos.
- **Map state:** the 9F HP Up is already taken. Event flags are initialized
  on entering 9F, which the player's house normally does.

### Route to the roof

Coordinates are map squares, x rightward and y downward:

1. 9F: down 1, left 2, down 1, then left onto the warp panel at (2,5) → 8F.
2. 8F: up 4, left 5, then left onto the panel at (10,3) → back to 9F at
   (12,7).
3. 9F: left 1, down 2, left 3, then left onto the ladder at (7,9) → roof.
4. The event starts by itself; press A for text.

Wild Pokémon can appear on 8F and 9F; run and carry on.


## Testing in an emulator

The event was verified headlessly with PyBoy (`pip3 install pyboy`),
driving the debug ROM with scripts. They:

- press buttons,
- pathfind the route above,
- run from wild battles,
- save a screenshot every 4 frames,
- log the girls' and player's positions from RAM, using the `.sym` file.

That's how the overlap checks, shot timings and side-by-side comparisons with
the reference video were made.

### Helper scripts

The scripts are in this session's scratch folder, which is temporary:

`/private/tmp/claude-501/-Users-joey-Documents-GitHub-pokecrystal/c5a4a354-c0bc-444e-a301-4a3c6e0db309/scratchpad/`

| Script | What it does |
|---|---|
| `drive.py` | PyBoy wrapper: start a new game, step, walk, run from battles |
| `path.py` | pathfinder over Tin Tower 7F–9F and their warps |
| `record.py` | play to the roof and record the event (`python3 record.py <out_dir>`) |
| `build_roof.py` | draw the roof tiles and rebuild blocks, collision and map |
| `gen_dance2.py` | generate the dance lanes (`python3 gen_dance2.py lanes.asm`) |
| `png2.py`, `render.py` | 2-bit PNG writer; map and tileset preview renderer |

Copy them somewhere permanent (for example a `tools/ho_oh_event/` folder) if
you want to keep them. They read and write repo paths, so run them from the
repo root.

### Quick manual check

Build the debug ROM, open it in mGBA, choose NEW GAME, and follow the route.


## Git: fork, branch and pushing

| Remote or branch | Points at |
|---|---|
| `origin` | your fork, `josephnavarro/pokecrystal` |
| `upstream` | `pret/pokecrystal` |
| `ho-oh-event` | the work; it tracks `origin/ho-oh-event` |
| `master` | tracks `upstream/master` |

```
git switch ho-oh-event
git add <files> && git commit        # commit as usual
git push                             # goes to your fork only
git fetch upstream                   # get pret's latest
git rebase upstream/master           # optional: replay the branch on top of it
```

Built ROMs (`*.gbc`) and generated graphics are git-ignored.


## Limits and gotchas

- **Sprites per scanline:** the Game Boy draws at most 10 sprites per line.
  The silhouette and diver use 8 on their rows, so sparkles or leaves there
  can drop out briefly.
- **Sprite count:** 40 sprites total. The silhouette shot uses 24 plus 16
  sparkles; the dive uses 32 plus 8 leaves.
- **Bank space:** the tower tiles and the cutscene art are near bank limits.
  If a link error says a section "would overflow", move a section to a bank
  with space in `layout.link`, using `pokecrystal.map` to find free banks.
  "Egg Moves" was moved to bank `$60` for this reason.
- **Object numbers:** in map scripts, object constants are one more than the
  engine's map-object index (`object_const_def` starts at 2). Assembly that
  looks up objects directly must subtract 1.
- **Block IDs:** stay at or below `$7f` (block loading wraps past 128).
- **Camera moves around full-screen specials:** if a script moves the camera
  right before a full-screen special, call `reanchormap` first. If it scrolls
  the map right after one, make sure `hBGMapMode` is 0.
