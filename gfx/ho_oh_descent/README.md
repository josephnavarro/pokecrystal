# Ho-Oh descent cutscene art

The cutscene in `engine/events/ho_oh_descent.asm` shows three pictures that
are loaded from this folder. The files here now are placeholders; replace
them with your own art and run `make`. The build checks each picture's size
and color limits and fails with a message if one is off.

Only use art you have the rights to use.

## `closeup.png`: the close-up

- **128 × 96 pixels**, full color.
- Each 8 × 8 tile can use at most **4 colors**, and the whole picture at most
  **7 palettes** of 4 colors. The sky's palette is separate, so the picture's
  background must be painted into the picture itself (the cutscene sky is
  RGB `15,23,31` in Game Boy Color values, about `#7BBDFF`).
- At most **256 unique tiles** (repeated tiles are merged).
- Shown between the black letterbox bars at screen x 32–159, y 24–119. It
  slides in from the right edge at 5 pixels per frame, then holds.

## `silhouette.png`: the flying silhouette

- **64 pixels wide**, made of **48-pixel-tall frames stacked top to bottom**
  (so 48, 96, 144, … pixels tall), 1 to 5 frames.
- Transparent background (PNG alpha), and at most **3 other colors** for the
  whole picture (one sprite palette).
- Flies right to left above the clouds with its top at screen y 38, at
  1.125 pixels per frame, leaving sparkles behind it.
- Frame order and timing come from `HoOhDescentSilhouetteSequence`
  (frame, frames shown; default: frame 0 for 45 frames, frame 1 for 15).

## `diver.png`: the diving figure

- **64 pixels wide**, made of **64-pixel-tall frames stacked top to bottom**,
  1 to 4 frames.
- Transparent background, and up to **4 sprite palettes** of 3 colors each.
  Each 8 × 16 block (aligned to the frame's top-left) must stick to one
  palette.
- Frame 0 is shown while it dives in from above the screen; it then stops
  with its top-left at screen (23, 42) and hovers.
- Hover order and timing come from `HoOhDescentDiverHoverSequence`
  (default: frames 0, 1, 0, 2 for 12, 24, 12 and 12 frames).

## Hardware limits to keep in mind

- The silhouette and diver are built from 8 × 16 sprites, 8 across. The Game
  Boy draws at most 10 sprites per scanline, so sparkles or leaves that share
  its rows can drop out briefly.
- Frames that go past a picture's last frame show its last frame instead.
- Shot lengths and speeds are the `HOOHDESCENT_*` constants at the top of
  `engine/events/ho_oh_descent.asm`.
