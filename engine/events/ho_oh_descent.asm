; Full-screen cutscene played on the Tin Tower roof before Ho-Oh appears.
;
; Shots (60 frames per second):
; - white, then a letterboxed sky; a close-up picture slides in from the right
; - black cut; a silhouette flies right to left above the clouds, leaving sparkles
; - black cut; a figure dives in from above and hovers among falling leaves
; - white, then back to the roof
;
; The close-up, silhouette and diver pictures are slots filled from
; gfx/ho_oh_descent/{closeup,silhouette,diver}.png; see
; gfx/ho_oh_descent/README.md for their sizes and color limits.

	const_def
	const HOOHDESCENT_BG_SKY         ; $00
	const HOOHDESCENT_BG_BLACK       ; $01
	const HOOHDESCENT_BG_CLOUD_TOP   ; $02-$05
	const_skip 3
	const HOOHDESCENT_BG_CLOUD_MID   ; $06-$09
	const_skip 3
	const HOOHDESCENT_BG_CLOUD_FILL  ; $0a
	const HOOHDESCENT_BG_STREAK      ; $0b
	const HOOHDESCENT_BG_HAZE        ; $0c

; 8x16 objects: each small graphic is followed by a blank tile
DEF HOOHDESCENT_OB_SPARKLE_BIG   EQU $00
DEF HOOHDESCENT_OB_SPARKLE_SMALL EQU $02
DEF HOOHDESCENT_OB_LEAF_1        EQU $04
DEF HOOHDESCENT_OB_LEAF_2        EQU $06

; object palettes
DEF HOOHDESCENT_PAL_SPARKLE    EQU 0
DEF HOOHDESCENT_PAL_LEAF       EQU 1
DEF HOOHDESCENT_PAL_SILHOUETTE EQU 2
DEF HOOHDESCENT_PAL_DIVER      EQU 3 ; up to 4 palettes

; shot timing, in frames (measured from the reference video)
DEF HOOHDESCENT_WHITE_IN_FRAMES     EQU 96
DEF HOOHDESCENT_SKY_FRAMES          EQU 176
DEF HOOHDESCENT_CLOSEUP_SLIDE_SPEED EQU 5   ; pixels per frame
DEF HOOHDESCENT_CLOSEUP_HOLD_FRAMES EQU 60
DEF HOOHDESCENT_BLACK_FRAMES        EQU 30
DEF HOOHDESCENT_SILHOUETTE_SPEED    EQU 9   ; eighths of a pixel per frame
DEF HOOHDESCENT_CLOUDS_TAIL_FRAMES  EQU 110
DEF HOOHDESCENT_DIVE_SPEED          EQU 5   ; half pixels per frame
DEF HOOHDESCENT_HOVER_FRAMES        EQU 190
DEF HOOHDESCENT_WHITE_OUT_FRAMES    EQU 132
DEF HOOHDESCENT_SPARKLE_LIFE        EQU 90

; layout
DEF HOOHDESCENT_LETTERBOX_ROWS     EQU 3
DEF HOOHDESCENT_CLOSEUP_WIDTH      EQU 16 ; tiles
DEF HOOHDESCENT_CLOSEUP_HEIGHT     EQU 12 ; tiles
DEF HOOHDESCENT_CLOSEUP_WX         EQU 7 + (SCREEN_WIDTH - HOOHDESCENT_CLOSEUP_WIDTH) * TILE_WIDTH
DEF HOOHDESCENT_WX_HIDDEN          EQU 7 + SCREEN_WIDTH_PX
DEF HOOHDESCENT_CLOUD_ROW          EQU 13
DEF HOOHDESCENT_SILHOUETTE_WIDTH   EQU 8 ; 8x16 objects across (64 pixels)
DEF HOOHDESCENT_SILHOUETTE_ROWS    EQU 3 ; 8x16 objects down (48 pixels)
DEF HOOHDESCENT_SILHOUETTE_TOP     EQU 38 ; screen y
DEF HOOHDESCENT_SILHOUETTE_TRAVEL  EQU SCREEN_WIDTH_PX + HOOHDESCENT_SILHOUETTE_WIDTH * TILE_WIDTH
DEF HOOHDESCENT_DIVER_WIDTH        EQU 8 ; 8x16 objects across (64 pixels)
DEF HOOHDESCENT_DIVER_ROWS         EQU 4 ; 8x16 objects down (64 pixels)
DEF HOOHDESCENT_DIVER_LEFT         EQU 23 ; screen x
DEF HOOHDESCENT_DIVER_TOP          EQU 42 ; screen y once it stops diving
DEF HOOHDESCENT_DIVER_POS_OFFSET   EQU 64 ; wHoOhDescentObjPos = y + 64

; jumptable indexes that select what object is drawn
DEF HOOHDESCENT_FIRST_DIVE_STATE EQU 9 ; .DiveStart

	pushs

SECTION "Ho-Oh Descent Graphics", ROMX

HoOhDescentCloseupGFX:
INCBIN "gfx/ho_oh_descent/closeup.2bpp"
.End:
HoOhDescentCloseupTilemap:
INCBIN "gfx/ho_oh_descent/closeup.tilemap"
.End:
HoOhDescentCloseupAttrmap:
INCBIN "gfx/ho_oh_descent/closeup.attrmap"
.End:
HoOhDescentCloseupPalettes:
INCBIN "gfx/ho_oh_descent/closeup.palettes"
.End:

HoOhDescentSilhouetteGFX:
INCBIN "gfx/ho_oh_descent/silhouette.2bpp"
.End:
HoOhDescentSilhouettePalette:
INCBIN "gfx/ho_oh_descent/silhouette.palettes", 0, 1 palettes

HoOhDescentDiverGFX:
INCBIN "gfx/ho_oh_descent/diver.2bpp"
.End:
HoOhDescentDiverAttrmap:
INCBIN "gfx/ho_oh_descent/diver.attrmap"
.End:
HoOhDescentDiverPalettes:
INCBIN "gfx/ho_oh_descent/diver.palettes"
.End:

HoOhDescentCloudsMap:
; sky, a hazy horizon, then the tops of the clouds
for row, TILEMAP_HEIGHT
	for col, TILEMAP_WIDTH
		if row < HOOHDESCENT_CLOUD_ROW - 1
			db HOOHDESCENT_BG_SKY
		elif row == HOOHDESCENT_CLOUD_ROW - 1
			db HOOHDESCENT_BG_HAZE
		elif row == HOOHDESCENT_CLOUD_ROW
			db HOOHDESCENT_BG_CLOUD_TOP + col % 4
		elif row == HOOHDESCENT_CLOUD_ROW + 1
			db HOOHDESCENT_BG_CLOUD_MID + col % 4
		else
			db HOOHDESCENT_BG_CLOUD_FILL
		endc
	endr
endr

HoOhDescentStreaksMap:
; streaks of light scattered in a pattern that wraps seamlessly
for row, TILEMAP_HEIGHT
	for col, TILEMAP_WIDTH
		if (col * 3 + row * 5) % 8 == 0
			db HOOHDESCENT_BG_STREAK
		else
			db HOOHDESCENT_BG_SKY
		endc
	endr
endr

HoOhDescentZeroAttrmap:
	ds TILEMAP_AREA, 0

	pops

; check the slot pictures, so a wrong size fails the build instead of the cutscene
DEF CLOSEUP_TILES EQU (HoOhDescentCloseupGFX.End - HoOhDescentCloseupGFX) / TILE_SIZE
	assert CLOSEUP_TILES <= 256, \
		"closeup.png has more than 256 unique tiles"
	assert HoOhDescentCloseupTilemap.End - HoOhDescentCloseupTilemap == HOOHDESCENT_CLOSEUP_WIDTH * HOOHDESCENT_CLOSEUP_HEIGHT, \
		"closeup.png must be 128x96 pixels"
	assert HoOhDescentCloseupPalettes.End - HoOhDescentCloseupPalettes <= 7 palettes, \
		"closeup.png uses more than 7 palettes"

DEF SILHOUETTE_TILES_PER_COLUMN EQU (HoOhDescentSilhouetteGFX.End - HoOhDescentSilhouetteGFX) / TILE_SIZE / HOOHDESCENT_SILHOUETTE_WIDTH
DEF SILHOUETTE_FRAMES EQU SILHOUETTE_TILES_PER_COLUMN / (HOOHDESCENT_SILHOUETTE_ROWS * 2)
	assert SILHOUETTE_FRAMES >= 1 && SILHOUETTE_TILES_PER_COLUMN == SILHOUETTE_FRAMES * HOOHDESCENT_SILHOUETTE_ROWS * 2, \
		"silhouette.png must be 64 pixels wide, with 48-pixel-tall frames"
	assert SILHOUETTE_TILES_PER_COLUMN * HOOHDESCENT_SILHOUETTE_WIDTH <= 256, \
		"silhouette.png has more than 5 frames"

DEF DIVER_TILES_PER_COLUMN EQU (HoOhDescentDiverGFX.End - HoOhDescentDiverGFX) / TILE_SIZE / HOOHDESCENT_DIVER_WIDTH
DEF DIVER_FRAMES EQU DIVER_TILES_PER_COLUMN / (HOOHDESCENT_DIVER_ROWS * 2)
	assert DIVER_FRAMES >= 1 && DIVER_TILES_PER_COLUMN == DIVER_FRAMES * HOOHDESCENT_DIVER_ROWS * 2, \
		"diver.png must be 64 pixels wide, with 64-pixel-tall frames"
	assert DIVER_TILES_PER_COLUMN * HOOHDESCENT_DIVER_WIDTH <= 256, \
		"diver.png has more than 4 frames"
	assert HoOhDescentDiverPalettes.End - HoOhDescentDiverPalettes <= 4 palettes, \
		"diver.png uses more than 4 palettes"

_HoOhDescent::
	ldh a, [rWBK]
	push af
	ld a, BANK(wHoOhDescent)
	ldh [rWBK], a

	ldh a, [hSCX]
	push af
	ldh a, [hSCY]
	push af
	ldh a, [hWY]
	push af
	ldh a, [hBGMapMode]
	push af
	ld hl, hVBlank
	ld a, [hl]
	push af

	call HoOhDescent_Init
	ld hl, hVBlank
	ld [hl], VBLANK_CUTSCENE_CGB

.loop
	ld a, [wJumptableIndex]
	bit JUMPTABLE_EXIT_F, a
	jr nz, .done
	call HoOhDescent_Jumptable
	call HoOhDescent_UpdateSparkles
	call HoOhDescent_DrawSprites
	ld hl, wHoOhDescentTimer
	inc [hl]
	call PushLYOverrides
	call DelayFrame
	ld a, [wHoOhDescentWX]
	ldh [rWX], a
	jr .loop

.done
	call ClearSprites
	xor a
	ldh [hLCDCPointer], a
	ld [wRequested2bppSource], a
	ld [wRequested2bppSource + 1], a
	ld [wRequested2bppDest], a
	ld [wRequested2bppDest + 1], a
	ld [wRequested2bppSize], a
	ld hl, rLCDC
	res B_LCDC_OBJ_SIZE, [hl]

	pop af
	ldh [hVBlank], a
	pop af
	ldh [hBGMapMode], a
	pop af
	ldh [hWY], a
	ldh [rWY], a
	pop af
	ldh [hSCY], a
	pop af
	ldh [hSCX], a
	ldh a, [hWX]
	ldh [rWX], a

	pop af
	ldh [rWBK], a
	ret

HoOhDescent_Init:
	call ClearSprites
	xor a
	ldh [hBGMapMode], a
	ldh [hSCX], a
	ldh [hSCY], a
	ldh [hLCDCPointer], a
	ld [wJumptableIndex], a
	ld hl, wHoOhDescent
	ld bc, wHoOhDescentEnd - wHoOhDescent
	call ByteFill
	ld a, -1
	ld [wHoOhDescentObjFrame], a
	ld a, HOOHDESCENT_WX_HIDDEN
	ld [wHoOhDescentWX], a

	ld hl, wLYOverrides
	ld bc, wLYOverridesEnd - wLYOverrides
	xor a
	call ByteFill
	ld hl, wLYOverridesBackup
	ld bc, wLYOverridesBackupEnd - wLYOverridesBackup
	xor a
	call ByteFill

; The screen is already white, so build the first shot with the LCD off.
	ld a, $ff
	call HoOhDescent_FillPalettes
	call DisableLCD
; The cutscene VBlank skips OAM updates on frames that change palettes,
; so clear out the overworld's sprites now.
	call hTransferShadowOAM
	ld hl, rLCDC
	set B_LCDC_OBJ_SIZE, [hl]
	ld a, HOOHDESCENT_WX_HIDDEN
	ldh [rWX], a
	ld a, HOOHDESCENT_LETTERBOX_ROWS * TILE_WIDTH
	ldh [hWY], a
	ldh [rWY], a

	ld hl, HoOhDescentBGGFX
	ld de, vTiles2
	ld bc, HoOhDescentBGGFX.End - HoOhDescentBGGFX
	call CopyBytes
	ld hl, HoOhDescentOBGFX
	ld de, vTiles0
	ld bc, HoOhDescentOBGFX.End - HoOhDescentOBGFX
	call CopyBytes

	call HoOhDescent_LoadCloseup

; letterboxed sky
	ld a, HOOHDESCENT_BG_SKY
	call HoOhDescent_FillBGMap
	hlbgcoord 0, 0
	ld a, HOOHDESCENT_BG_BLACK
	ld bc, HOOHDESCENT_LETTERBOX_ROWS * TILEMAP_WIDTH
	call ByteFill
	hlbgcoord 0, SCREEN_HEIGHT - HOOHDESCENT_LETTERBOX_ROWS
	ld a, HOOHDESCENT_BG_BLACK
	ld bc, HOOHDESCENT_LETTERBOX_ROWS * TILEMAP_WIDTH
	call ByteFill

	call EnableLCD
	ret

HoOhDescent_LoadCloseup:
; Load the close-up picture into VRAM bank 1 and lay it out on the window,
; above the bottom letterbox. The LCD must be off.
	ld a, 1
	ldh [rVBK], a
; the first 128 tiles go to $9000, the rest to $8800
	ld a, BANK(HoOhDescentCloseupGFX)
	ld hl, HoOhDescentCloseupGFX
	ld de, vTiles2
if CLOSEUP_TILES > 128
	ld bc, 128 tiles
	call FarCopyBytes
	ld a, BANK(HoOhDescentCloseupGFX)
	ld hl, HoOhDescentCloseupGFX + 128 tiles
	ld de, vTiles1
	ld bc, (CLOSEUP_TILES - 128) tiles
else
	ld bc, CLOSEUP_TILES tiles
endc
	call FarCopyBytes
	xor a
	ldh [rVBK], a

; window rows: the picture, then the bottom letterbox
	ld hl, vBGMap1
	ld de, 0 ; index into the tilemap and attrmap
	ld b, HOOHDESCENT_CLOSEUP_HEIGHT
.row
	ld c, HOOHDESCENT_CLOSEUP_WIDTH
	push hl
.column
	push hl
	ld hl, HoOhDescentCloseupTilemap
	add hl, de
	ld a, BANK(HoOhDescentCloseupTilemap)
	call GetFarByte
	pop hl
	ld [hl], a
	push hl
	ld hl, HoOhDescentCloseupAttrmap
	add hl, de
	ld a, BANK(HoOhDescentCloseupAttrmap)
	call GetFarByte
	pop hl
; the picture's palettes follow the sky's, and its tiles are in bank 1
	and BG_PALETTE
	inc a
	or BG_BANK1
	push af
	ld a, 1
	ldh [rVBK], a
	pop af
	ld [hli], a
	xor a
	ldh [rVBK], a
	inc de
	dec c
	jr nz, .column
	pop hl
	push bc
	ld bc, TILEMAP_WIDTH
	add hl, bc
	pop bc
	dec b
	jr nz, .row

; hl = the first row under the picture
	push hl
	ld a, HOOHDESCENT_BG_BLACK
	ld bc, HOOHDESCENT_LETTERBOX_ROWS * TILEMAP_WIDTH
	call ByteFill
	pop hl
	ld a, 1
	ldh [rVBK], a
	xor a
	ld bc, HOOHDESCENT_LETTERBOX_ROWS * TILEMAP_WIDTH
	call ByteFill
	xor a
	ldh [rVBK], a
	ret

HoOhDescent_Jumptable:
	jumptable .Jumptable, wJumptableIndex

.Jumptable:
	dw .WhiteIn          ; 0
	dw .SkyHold          ; 1
	dw .CloseupSlide     ; 2
	dw .CloseupHold      ; 3
	dw .CutToClouds      ; 4
	dw .CloudsStart      ; 5
	dw .SilhouetteFlight ; 6
	dw .CloudsTail       ; 7
	dw .CutToDive        ; 8
	dw .DiveStart        ; 9
	dw .Dive             ; 10
	dw .Hover            ; 11
	dw .WhiteOut         ; 12

.Next:
	ld hl, wJumptableIndex
	inc [hl]
	xor a
	ld [wHoOhDescentTimer], a
	ret

.WhiteIn:
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_WHITE_IN_FRAMES
	ret c
	call HoOhDescent_LoadSkyPalettes
	ld hl, HoOhDescentCloseupPalettes
	ld de, wBGPals1 palette 1
	ld bc, HoOhDescentCloseupPalettes.End - HoOhDescentCloseupPalettes
	call HoOhDescent_LoadFarPalettes
	jr .Next

.SkyHold:
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_SKY_FRAMES
	ret c
	ld de, SFX_SHINE
	call PlaySFX
	jr .Next

.CloseupSlide:
	ld hl, wHoOhDescentWX
	ld a, [hl]
	sub HOOHDESCENT_CLOSEUP_SLIDE_SPEED
	jr c, .slid_in
	cp HOOHDESCENT_CLOSEUP_WX
	jr c, .slid_in
	ld [hl], a
	ret

.slid_in
	ld [hl], HOOHDESCENT_CLOSEUP_WX
	jr .Next

.CloseupHold:
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_CLOSEUP_HOLD_FRAMES
	ret c
	jr .Next

.CutToClouds:
; Black out the screen, and stream in the next shot behind it.
; (the timer has already ticked once when a state first runs)
	ld a, [wHoOhDescentTimer]
	cp 1
	jr nz, .wait_black
	call HoOhDescent_BlackOut
	ld de, HoOhDescentCloudsMap
	call HoOhDescent_StreamBGMap
	ld de, HoOhDescentSilhouetteGFX
	ld c, (HoOhDescentSilhouetteGFX.End - HoOhDescentSilhouetteGFX) / TILE_SIZE
	call HoOhDescent_StreamObjectTiles
.wait_black
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_BLACK_FRAMES
	ret c
	jp .Next

.CloudsStart:
	call HoOhDescent_LoadSkyPalettes
	ld hl, HoOhDescentSilhouettePalette
	ld de, wOBPals1 palette HOOHDESCENT_PAL_SILHOUETTE
	ld bc, 1 palettes
	call HoOhDescent_LoadFarPalettes
	xor a
	ld [wHoOhDescentObjPos], a
	ld [wHoOhDescentObjSubpixel], a
	ld hl, HoOhDescentSilhouetteSequence
	call HoOhDescent_StartAnimation
	ld a, LOW(rSCX)
	ldh [hLCDCPointer], a
	ld de, SFX_TWINKLE
	call PlaySFX
	jp .Next

.SilhouetteFlight:
	call HoOhDescent_DriftClouds
; fly left at HOOHDESCENT_SILHOUETTE_SPEED / 8 pixels per frame
	ld hl, wHoOhDescentObjSubpixel
	ld a, [hl]
	add HOOHDESCENT_SILHOUETTE_SPEED
	ld b, a
	and %111
	ld [hl], a
	ld a, b
	srl a
	srl a
	srl a
	ld hl, wHoOhDescentObjPos
	add [hl]
	ld [hl], a
	cp HOOHDESCENT_SILHOUETTE_TRAVEL
	jr nc, .flown_past
	ld hl, HoOhDescentSilhouetteSequence
	call HoOhDescent_Animate
	ld a, [wHoOhDescentTimer]
	and %111
	ret nz
	jp HoOhDescent_SpawnSparkle

.flown_past
	ld a, -1
	ld [wHoOhDescentObjFrame], a
	jp .Next

.CloudsTail:
	call HoOhDescent_DriftClouds
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_CLOUDS_TAIL_FRAMES
	ret c
	jp .Next

.CutToDive:
	ld a, [wHoOhDescentTimer]
	cp 1
	jr nz, .wait_black_2
	xor a
	ldh [hLCDCPointer], a
	ldh [hSCX], a
	ldh [hSCY], a
	call HoOhDescent_BlackOut
	ld de, HoOhDescentStreaksMap
	call HoOhDescent_StreamBGMap
	ld de, HoOhDescentDiverGFX
	ld c, (HoOhDescentDiverGFX.End - HoOhDescentDiverGFX) / TILE_SIZE
	call HoOhDescent_StreamObjectTiles
.wait_black_2
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_BLACK_FRAMES
	ret c
	jp .Next

.DiveStart:
	call HoOhDescent_LoadSkyPalettes
	ld hl, HoOhDescentDiverPalettes
	ld de, wOBPals1 palette HOOHDESCENT_PAL_DIVER
	ld bc, HoOhDescentDiverPalettes.End - HoOhDescentDiverPalettes
	call HoOhDescent_LoadFarPalettes
	call HoOhDescent_InitLeaves
	xor a
	ld [wHoOhDescentObjPos], a ; above the screen
	ld [wHoOhDescentObjSubpixel], a
	ld [wHoOhDescentObjFrame], a
	ld de, SFX_METRONOME
	call PlaySFX
	jp .Next

.Dive:
	call .FallingBackground
; come down at HOOHDESCENT_DIVE_SPEED / 2 pixels per frame
	ld hl, wHoOhDescentObjSubpixel
	ld a, [hl]
	add HOOHDESCENT_DIVE_SPEED
	ld b, a
	and 1
	ld [hl], a
	ld a, b
	srl a
	ld hl, wHoOhDescentObjPos
	add [hl]
	cp HOOHDESCENT_DIVER_TOP + HOOHDESCENT_DIVER_POS_OFFSET
	jr nc, .landed
	ld [hl], a
	ret

.landed
	ld [hl], HOOHDESCENT_DIVER_TOP + HOOHDESCENT_DIVER_POS_OFFSET
	ld hl, HoOhDescentDiverHoverSequence
	call HoOhDescent_StartAnimation
	jp .Next

.Hover:
	call .FallingBackground
	ld hl, HoOhDescentDiverHoverSequence
	call HoOhDescent_Animate
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_HOVER_FRAMES
	ret c
; cut straight to white
	ld a, $ff
	call HoOhDescent_FillPalettes
	ld a, -1
	ld [wHoOhDescentObjFrame], a
	call HoOhDescent_ClearLeaves
	jp .Next

.FallingBackground:
	ldh a, [hSCY]
	sub 3
	ldh [hSCY], a
	jp HoOhDescent_UpdateLeaves

.WhiteOut:
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_WHITE_OUT_FRAMES
	ret c
	ld hl, wJumptableIndex
	set JUMPTABLE_EXIT_F, [hl]
	ret

HoOhDescentSilhouetteSequence:
; frame, duration in frames; frames beyond the picture's use its last frame
	db 0, 45
	db 1, 15
	db -1

HoOhDescentDiverHoverSequence:
	db 0, 12
	db 1, 24
	db 0, 12
	db 2, 12
	db -1

HoOhDescent_BlackOut:
; Black out every palette, and hide the window and sprites.
	xor a
	call HoOhDescent_FillPalettes
	ld a, HOOHDESCENT_WX_HIDDEN
	ld [wHoOhDescentWX], a
	ldh [rWX], a
	ld a, -1
	ld [wHoOhDescentObjFrame], a
	call HoOhDescent_ClearSparkles
	call HoOhDescent_ClearLeaves
	jp HoOhDescent_DrawSprites

HoOhDescent_StreamBGMap:
; Copy the 32x32 map at de to the BG map, with all-zero attributes,
; while the screen is blacked out.
	ld hl, vBGMap0
	ld b, BANK(HoOhDescentCloudsMap)
	ld c, TILEMAP_AREA / TILE_SIZE
	call Get2bppViaHDMA
	ld a, 1
	ldh [rVBK], a
	ld de, HoOhDescentZeroAttrmap
	ld hl, vBGMap0
	ld b, BANK(HoOhDescentZeroAttrmap)
	ld c, TILEMAP_AREA / TILE_SIZE
	call Get2bppViaHDMA
	xor a
	ldh [rVBK], a
	ret

HoOhDescent_StreamObjectTiles:
; Copy c tiles from BANK(HoOhDescentSilhouetteGFX):de to vTiles0 in VRAM bank 1,
; at most 64 tiles at a time, while the screen is blacked out.
	ld hl, vTiles0
.loop
	ld a, c
	and a
	ret z
	cp 64
	jr c, .got_count
	ld a, 64
.got_count
	ld b, a ; tiles in this chunk
	push bc
	push de
	push hl
	ld c, b
	ld b, BANK(HoOhDescentSilhouetteGFX)
	ld a, 1
	ldh [rVBK], a
	call Get2bppViaHDMA
	xor a
	ldh [rVBK], a
	pop hl
	pop de
	pop bc
; advance the source and destination by b tiles
	push bc
	push hl
	ld l, b
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld b, h
	ld c, l
	pop hl
	add hl, bc
	ld a, e
	add c
	ld e, a
	ld a, d
	adc b
	ld d, a
	pop bc
	ld a, c
	sub b
	ld c, a
	jr .loop

HoOhDescent_FillPalettes:
; Fill every BG and object palette with color byte a (0 = black, $ff = white).
	ld hl, wBGPals1
	ld bc, 16 palettes
	push af
	call ByteFill
	pop af
	ld hl, wBGPals2
	ld bc, 16 palettes
	call ByteFill
	ld a, TRUE
	ldh [hCGBPalUpdate], a
	ret

HoOhDescent_LoadSkyPalettes:
; The sky, sparkle and leaf palettes, with everything else black.
	xor a
	ld hl, wBGPals1
	ld bc, 16 palettes
	call ByteFill
	ld hl, HoOhDescentSkyPalette
	ld de, wBGPals1
	ld bc, 1 palettes
	call CopyBytes
	ld hl, HoOhDescentObjectPalettes
	ld de, wOBPals1
	ld bc, 2 palettes
	call CopyBytes
	jr HoOhDescent_ApplyPalettes

HoOhDescent_LoadFarPalettes:
; Copy bc bytes of palettes from BANK(HoOhDescentCloseupPalettes):hl to de,
; within wBGPals1 or wOBPals1.
	ld a, BANK(HoOhDescentCloseupPalettes)
	call FarCopyBytes
	; fallthrough

HoOhDescent_ApplyPalettes:
	ld hl, wBGPals1
	ld de, wBGPals2
	ld bc, 16 palettes
	call CopyBytes
	ld a, TRUE
	ldh [hCGBPalUpdate], a
	ret

HoOhDescent_FillBGMap:
; Fill the whole BG map with tile a, using palette 0 without priority.
	ld hl, vBGMap0
	ld bc, TILEMAP_AREA
	call ByteFill
	ld a, 1
	ldh [rVBK], a
	ld hl, vBGMap0
	ld bc, TILEMAP_AREA
	xor a
	call ByteFill
	xor a
	ldh [rVBK], a
	ret

HoOhDescent_DriftClouds:
; Drift the clouds sideways, leaving the sky above them still.
	ld a, [wHoOhDescentTimer]
	and %11
	jr nz, .no_scroll
	ld hl, wHoOhDescentCloudScroll
	inc [hl]
.no_scroll
	ld hl, wLYOverridesBackup
	ld bc, HOOHDESCENT_CLOUD_ROW * TILE_WIDTH
	xor a
	call ByteFill
	ld bc, SCREEN_HEIGHT_PX - HOOHDESCENT_CLOUD_ROW * TILE_WIDTH
	ld a, [wHoOhDescentCloudScroll]
	jp ByteFill

HoOhDescent_StartAnimation:
; Start the frame sequence at hl.
	ld a, l
	ld [wHoOhDescentAnimPointer], a
	ld a, h
	ld [wHoOhDescentAnimPointer + 1], a
	jr HoOhDescent_LoadAnimationStep

HoOhDescent_Animate:
; Advance the frame sequence that starts at hl, looping at its end.
	ld a, [wHoOhDescentAnimTimer]
	and a
	jr z, .next_step
	dec a
	ld [wHoOhDescentAnimTimer], a
	ret

.next_step
	ld d, h
	ld e, l
	ld hl, wHoOhDescentAnimPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	inc hl
	ld a, [hl]
	cp -1
	jr nz, .got_step
	ld h, d
	ld l, e
.got_step
	ld a, l
	ld [wHoOhDescentAnimPointer], a
	ld a, h
	ld [wHoOhDescentAnimPointer + 1], a
	; fallthrough

HoOhDescent_LoadAnimationStep:
	ld hl, wHoOhDescentAnimPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli] ; frame
	ld [wHoOhDescentObjFrame], a
	ld a, [hl] ; duration
	dec a
	ld [wHoOhDescentAnimTimer], a
	ret

HoOhDescent_ClearSparkles:
	ld hl, wHoOhDescentSparkles
	ld bc, HOOHDESCENT_NUM_SPARKLES * 3
	xor a
	jp ByteFill

HoOhDescent_ClearLeaves:
	ld hl, wHoOhDescentLeaves
	ld bc, HOOHDESCENT_NUM_LEAVES * 3
	xor a
	jp ByteFill

HoOhDescent_SpawnSparkle:
; Leave a sparkle behind (to the right of) the silhouette, if that is on screen.
	ld a, [wHoOhDescentObjPos]
	cp 45
	ret c
	cp 200
	ret nc
	ld a, [wHoOhDescentSparkleSlot]
	inc a
	cp HOOHDESCENT_NUM_SPARKLES
	jr c, .got_slot
	xor a
.got_slot
	ld [wHoOhDescentSparkleSlot], a
	ld c, a
	add a
	add c
	ld e, a
	ld d, 0
	ld hl, wHoOhDescentSparkles
	add hl, de
; x = the silhouette's rear (160 - pos + 44) + 0-15, as OAM x
	push hl
	call Random
	pop hl
	and %1111
	ld b, a
	ld a, [wHoOhDescentObjPos]
	cpl
	inc a
	add SCREEN_WIDTH_PX + 44 + OAM_X_OFS
	add b
	ld [hli], a
; y = the silhouette's lower half and below, as OAM y
	push hl
	call Random
	pop hl
	and %11111
	add HOOHDESCENT_SILHOUETTE_TOP + 18 + OAM_Y_OFS
	ld [hli], a
	ld [hl], HOOHDESCENT_SPARKLE_LIFE
	ret

HoOhDescent_UpdateSparkles:
	ld hl, wHoOhDescentSparkles + 2
	ld de, 3
	ld b, HOOHDESCENT_NUM_SPARKLES
.loop
	ld a, [hl]
	and a
	jr z, .next
	dec [hl]
.next
	add hl, de
	dec b
	jr nz, .loop
	ret

HoOhDescent_InitLeaves:
; Spread the leaves over the screen from top to bottom.
	ld hl, wHoOhDescentLeaves
	ld c, 0
.loop
	push hl
	call Random
	pop hl
	and %1111111
	add 24
	ld [hli], a ; x
	ld a, c
	swap a
	add a ; * 32
	add 8
	ld [hli], a ; y
	push hl
	call Random
	pop hl
	ld [hli], a ; sway phase
	inc c
	ld a, c
	cp HOOHDESCENT_NUM_LEAVES
	jr c, .loop
	ret

HoOhDescent_UpdateLeaves:
	ld hl, wHoOhDescentLeaves
	ld c, 0
.loop
	push hl
; odd leaves fall at half speed, for some depth
	inc hl
	ld a, c
	and 1
	jr z, .fall
	ld a, [wHoOhDescentTimer]
	and 1
	jr nz, .fell
.fall
	inc [hl]
.fell
	ld a, [hl]
	cp SCREEN_HEIGHT_PX + 16
	jr c, .sway
; back to the top, somewhere else
	ld [hl], 8
	dec hl
	push hl
	call Random
	pop hl
	and %1111111
	add 24
	ld [hli], a
.sway
; drift left and right a pixel every 4 frames
	inc hl
	inc [hl] ; phase
	ld b, [hl]
	pop hl
	push hl
	ld a, b
	and %11
	jr nz, .next
	bit 5, b
	jr z, .left
	inc [hl] ; x
	jr .next
.left
	dec [hl] ; x
.next
	pop hl
	inc hl
	inc hl
	inc hl
	inc c
	ld a, c
	cp HOOHDESCENT_NUM_LEAVES
	jr c, .loop
	ret

HoOhDescent_DrawSprites:
	ld hl, wShadowOAM
	ld a, [wHoOhDescentObjFrame]
	cp -1
	jr z, .sparkles
	ld a, [wJumptableIndex]
	cp HOOHDESCENT_FIRST_DIVE_STATE
	jr nc, .diver
	call HoOhDescent_DrawSilhouette
	jr .sparkles
.diver
	call HoOhDescent_DrawDiver

.sparkles
	ld de, wHoOhDescentSparkles
	ld b, HOOHDESCENT_NUM_SPARKLES
.sparkle_loop
	push bc
	ld a, [de] ; x
	ld c, a
	inc de
	ld a, [de] ; y
	ld b, a
	inc de
	ld a, [de] ; lifetime
	inc de
	and a
	jr z, .next_sparkle
; twinkle, then fade to a small sparkle
	cp 20
	jr c, .small_sparkle
	and %1000
	jr z, .small_sparkle
	ld a, HOOHDESCENT_OB_SPARKLE_BIG
	jr .got_sparkle_tile
.small_sparkle
	ld a, HOOHDESCENT_OB_SPARKLE_SMALL
.got_sparkle_tile
	push af
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	pop af
	ld [hli], a
	ld [hl], HOOHDESCENT_PAL_SPARKLE
	inc hl
.next_sparkle
	pop bc
	dec b
	jr nz, .sparkle_loop

; leaves
	ld de, wHoOhDescentLeaves
	ld b, HOOHDESCENT_NUM_LEAVES
.leaf_loop
	push bc
	ld a, [de] ; x
	ld c, a
	inc de
	ld a, [de] ; y
	ld b, a
	inc de
	ld a, [de] ; sway phase
	inc de
	push de
	ld e, a
	ld a, b
	and a
	jr z, .next_leaf
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, e
	and %10000
	ld a, HOOHDESCENT_OB_LEAF_1
	jr z, .got_leaf_tile
	ld a, HOOHDESCENT_OB_LEAF_2
.got_leaf_tile
	ld [hli], a
	ld a, e
	and %100000
	ld a, HOOHDESCENT_PAL_LEAF
	jr z, .got_leaf_attr
	or OAM_XFLIP
.got_leaf_attr
	ld [hli], a
.next_leaf
	pop de
	pop bc
	dec b
	jr nz, .leaf_loop

; hide the rest
.clear
	ld a, l
	cp LOW(wShadowOAMEnd)
	ret z
	xor a
	ld [hli], a
	jr .clear

HoOhDescent_DrawSilhouette:
; 8x16 objects in columns; column c's left edge is at screen x 160 - pos + 8c.
; Tile = column base + frame * rows * 2 + row * 2 (the picture is read by columns).
	ld a, [wHoOhDescentObjFrame]
	cp SILHOUETTE_FRAMES
	jr c, .got_frame
	ld a, SILHOUETTE_FRAMES - 1
.got_frame
	ld e, a
	add a
	add e
	add a ; * rows * 2
	ld e, a
	ld c, 0 ; column
.column
	ld a, c
	add a
	add a
	add a
	ld b, a ; 8c
	ld a, [wHoOhDescentObjPos]
	sub b
	jr c, .next_column ; still past the right edge
	jr z, .next_column
	cp SCREEN_WIDTH_PX + OAM_X_OFS
	jr nc, .next_column ; past the left edge
	ld b, a
	ld a, SCREEN_WIDTH_PX + OAM_X_OFS
	sub b
	ld b, a ; OAM x
	push de
	push hl
	ld hl, .ColumnBases
	ld d, 0
	ld a, e
	ld e, c
	add hl, de
	add [hl]
	pop hl
	ld e, a ; this column's first tile for the frame
	ld d, HOOHDESCENT_SILHOUETTE_TOP + OAM_Y_OFS
rept HOOHDESCENT_SILHOUETTE_ROWS
	ld a, d
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, OAM_BANK1 | HOOHDESCENT_PAL_SILHOUETTE
	ld [hli], a
	ld a, d
	add 16
	ld d, a
	inc e
	inc e
endr
	pop de
.next_column
	inc c
	ld a, c
	cp HOOHDESCENT_SILHOUETTE_WIDTH
	jr c, .column
	ret

.ColumnBases:
for column, HOOHDESCENT_SILHOUETTE_WIDTH
	db column * SILHOUETTE_TILES_PER_COLUMN
endr

HoOhDescent_DrawDiver:
; 8x16 objects in columns, with each object's palette taken from its top tile.
	ld a, [wHoOhDescentObjFrame]
	cp DIVER_FRAMES
	jr c, .got_frame
	ld a, DIVER_FRAMES - 1
.got_frame
	add a
	add a
	add a ; * rows * 2
	ld e, a
	ld c, 0 ; column
.column
	ld b, 0 ; row
.row
; OAM y = pos + 16 * row - 48, hidden while above the screen
	ld a, b
	swap a
	ld d, a
	ld a, [wHoOhDescentObjPos]
	add d
	sub HOOHDESCENT_DIVER_POS_OFFSET - OAM_Y_OFS
	jr c, .next_row
	jr z, .next_row
	ld [hli], a
	ld a, c
	add a
	add a
	add a
	add HOOHDESCENT_DIVER_LEFT + OAM_X_OFS
	ld [hli], a
; tile = column base + frame's first tile + row * 2
	push hl
	ld hl, .ColumnBases
	ld d, 0
	push de
	ld e, c
	add hl, de
	pop de
	ld a, [hl]
	add e
	add b
	add b
	ld d, a ; tile
	ld hl, HoOhDescentDiverAttrmap
	push de
	ld e, a
	ld d, 0
	add hl, de
	pop de
	ld a, BANK(HoOhDescentDiverAttrmap)
	call GetFarByte
	and OAM_PALETTE
	add HOOHDESCENT_PAL_DIVER
	or OAM_BANK1
	pop hl
	push af
	ld a, d
	ld [hli], a
	pop af
	ld [hli], a
.next_row
	inc b
	ld a, b
	cp HOOHDESCENT_DIVER_ROWS
	jr c, .row
	inc c
	ld a, c
	cp HOOHDESCENT_DIVER_WIDTH
	jr c, .column
	ret

.ColumnBases:
for column, HOOHDESCENT_DIVER_WIDTH
	db column * DIVER_TILES_PER_COLUMN
endr

HoOhDescentSkyPalette:
	RGB 15,23,31, 31,31,31, 22,26,31, 00,00,00

HoOhDescentObjectPalettes:
	RGB 31,31,31, 31,31,31, 31,29,06, 31,20,04 ; sparkles
	RGB 31,31,31, 31,24,04, 31,12,02, 18,06,02 ; leaves

HoOhDescentBGGFX:
INCBIN "gfx/overworld/ho_oh_descent_bg.2bpp"
.End:

HoOhDescentOBGFX:
INCBIN "gfx/overworld/ho_oh_descent_ob.2bpp"
.End:
