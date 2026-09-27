; Full-screen cutscene of a rainbow light coming down from the sky,
; played on the Tin Tower roof before Ho-Oh appears.

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

	const_def
	const HOOHDESCENT_OB_ORB         ; $00-$03 (and $04-$07 for the second frame)
	const_skip 7
	const HOOHDESCENT_OB_SPARKLE_BIG   ; $08
	const HOOHDESCENT_OB_SPARKLE_SMALL ; $09
	const HOOHDESCENT_OB_LEAF_1        ; $0a
	const HOOHDESCENT_OB_LEAF_2        ; $0b

DEF HOOHDESCENT_SPARKLE_LIFE EQU 24
DEF HOOHDESCENT_ORB_HOVER_Y  EQU 72 ; OAM y where the light stops coming down

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
	call HoOhDescent_CycleRainbow
	call HoOhDescent_DrawSprites
	ld hl, wHoOhDescentTimer
	inc [hl]
	call PushLYOverrides
	call DelayFrame
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

	pop af
	ldh [hVBlank], a
	pop af
	ldh [hBGMapMode], a
	pop af
	ldh [hWY], a
	pop af
	ldh [hSCY], a
	pop af
	ldh [hSCX], a

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

	ld hl, wLYOverrides
	ld bc, wLYOverridesEnd - wLYOverrides
	xor a
	call ByteFill
	ld hl, wLYOverridesBackup
	ld bc, wLYOverridesBackupEnd - wLYOverridesBackup
	xor a
	call ByteFill

	call DisableLCD
; The cutscene VBlank skips OAM updates on frames that change palettes,
; so clear out the overworld's sprites now.
	call hTransferShadowOAM
	ld a, SCREEN_HEIGHT_PX
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

	ld hl, HoOhDescentPalettes
	call HoOhDescent_LoadPalettes

	call EnableLCD
	ret

HoOhDescent_LoadPalettes:
; Load BG palette 0 and OBJ palettes 0-1 from hl (3 palettes),
; both as the current and the target palettes.
	push hl
	ld de, wBGPals1
	ld bc, 1 palettes
	call CopyBytes
	ld de, wOBPals1
	ld bc, 2 palettes
	call CopyBytes
	pop hl
	ld de, wBGPals2
	ld bc, 1 palettes
	call CopyBytes
	ld de, wOBPals2
	ld bc, 2 palettes
	call CopyBytes
	ld a, TRUE
	ldh [hCGBPalUpdate], a
	ret

HoOhDescent_Jumptable:
	jumptable .Jumptable, wJumptableIndex

.Jumptable:
	dw .Shot1Init
	dw .Shot1Rise
	dw .Shot2Init
	dw .Shot2Fly
	dw .Shot2Pan
	dw .Shot3Init
	dw .Shot3Descend
	dw .FadeToWhite
	dw .HoldWhite

.Next:
	ld hl, wJumptableIndex
	inc [hl]
	xor a
	ld [wHoOhDescentTimer], a
	ret

.Shot1Init:
; Letterboxed sky; a light rises up through it.
	call DisableLCD
	ld a, HOOHDESCENT_BG_SKY
	call HoOhDescent_FillBGMap
	hlbgcoord 0, 0
	call .Letterbox
	hlbgcoord 0, SCREEN_HEIGHT - 2
	call .Letterbox
	call EnableLCD

	ld a, 80
	ld [wHoOhDescentOrbX], a
	ld a, SCREEN_HEIGHT_PX + 16
	ld [wHoOhDescentOrbY], a
	ld de, SFX_SHINE
	call PlaySFX
	jr .Next

.Letterbox:
; Two rows of black drawn above sprites
	push hl
	ld a, HOOHDESCENT_BG_BLACK
	ld bc, 2 * TILEMAP_WIDTH
	call ByteFill
	pop hl
	ld a, 1
	ldh [rVBK], a
	ld a, BG_PRIO
	ld bc, 2 * TILEMAP_WIDTH
	call ByteFill
	xor a
	ldh [rVBK], a
	ret

.Shot1Rise:
	ld hl, wHoOhDescentOrbY
	ld a, [hl]
	and a
	jr z, .shot1_wait
	dec [hl]
	call HoOhDescent_GetSway
	add 76
	ld [wHoOhDescentOrbX], a
	ld a, [wHoOhDescentTimer]
	and %11
	call z, HoOhDescent_SpawnSparkle
	ret

.shot1_wait
	ld a, [wHoOhDescentTimer]
	cp SCREEN_HEIGHT_PX + 16 + 80
	ret c
	jr .Next

.Shot2Init:
; High above the clouds; the light streaks across the sky.
	call DisableLCD
	ld a, HOOHDESCENT_BG_SKY
	call HoOhDescent_FillBGMap
	hlbgcoord 0, 10
	ld a, HOOHDESCENT_BG_HAZE
	ld bc, TILEMAP_WIDTH
	call ByteFill
	hlbgcoord 0, 11
	ld a, HOOHDESCENT_BG_CLOUD_TOP
	call HoOhDescent_FillCloudRow
	hlbgcoord 0, 12
	ld a, HOOHDESCENT_BG_CLOUD_MID
	call HoOhDescent_FillCloudRow
	hlbgcoord 0, 13
	ld a, HOOHDESCENT_BG_CLOUD_FILL
	ld bc, (TILEMAP_HEIGHT - 13) * TILEMAP_WIDTH
	call ByteFill
	call EnableLCD

	call HoOhDescent_ClearSparkles
	ld a, LOW(rSCX)
	ldh [hLCDCPointer], a
	ld a, SCREEN_WIDTH_PX + 16
	ld [wHoOhDescentOrbX], a
	ld a, 64
	ld [wHoOhDescentOrbY], a
	ld de, SFX_TWINKLE
	call PlaySFX
	jp .Next

.Shot2Fly:
	call HoOhDescent_ScrollClouds
	ld hl, wHoOhDescentOrbX
	ld a, [hl]
	and a
	jr z, .shot2_wait
	dec [hl]
	call HoOhDescent_GetSway
	add 60
	ld [wHoOhDescentOrbY], a
	ld a, [wHoOhDescentTimer]
	and %11
	call z, HoOhDescent_SpawnSparkle
	ret

.shot2_wait
	ld a, [wHoOhDescentTimer]
	cp SCREEN_WIDTH_PX + 16 + 40
	ret c
	jp .Next

.Shot2Pan:
; Look down into the clouds
	call HoOhDescent_ScrollClouds
	ld hl, wHoOhDescentPanY
	inc [hl]
	ld a, [hl]
	ldh [hSCY], a
	cp 9 * TILE_WIDTH
	ret c
	jp .Next

.Shot3Init:
; Below the clouds; the light comes down through falling leaves.
	call DisableLCD
	xor a
	ldh [hLCDCPointer], a
	ldh [hSCX], a
	ldh [hSCY], a
	ld a, HOOHDESCENT_BG_SKY
	call HoOhDescent_FillBGMap
	call HoOhDescent_DrawStreaks
	call EnableLCD

	call HoOhDescent_ClearSparkles
	call HoOhDescent_InitLeaves
	ld a, 80
	ld [wHoOhDescentOrbX], a
	ld a, 1
	ld [wHoOhDescentOrbY], a
	ld de, SFX_METRONOME
	call PlaySFX
	jp .Next

.Shot3Descend:
	call .FallingBackground
	ld hl, wHoOhDescentOrbY
	ld a, [hl]
	cp HOOHDESCENT_ORB_HOVER_Y
	jr nc, .hover
	inc [hl]
	ld a, [wHoOhDescentTimer]
	and %11
	call z, HoOhDescent_SpawnSparkle
	ret

.hover
	ld a, [wHoOhDescentTimer]
	and %1
	call z, HoOhDescent_SpawnSparkle
	ld a, [wHoOhDescentTimer]
	cp HOOHDESCENT_ORB_HOVER_Y + 150
	ret c
	ld de, SFX_FLASH
	call PlaySFX
	jp .Next

.FallingBackground:
	ldh a, [hSCY]
	sub 3
	ldh [hSCY], a
	jp HoOhDescent_UpdateLeaves

.FadeToWhite:
	call .FallingBackground
	ld a, [wHoOhDescentTimer]
	ld c, a
	and %11
	ret nz
	ld a, c
	rrca
	rrca
	and %111 ; step
	cp 4
	jr nc, .faded
	ld hl, HoOhDescentFadePalettes
	ld bc, 3 palettes
	call AddNTimes
	jp HoOhDescent_LoadPalettes

.faded
	call HoOhDescent_ClearSparkles
	call HoOhDescent_ClearLeaves
	xor a
	ld [wHoOhDescentOrbY], a
	jp .Next

.HoldWhite:
	ld a, [wHoOhDescentTimer]
	cp 60
	ret c
	ld hl, wJumptableIndex
	set JUMPTABLE_EXIT_F, [hl]
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

HoOhDescent_FillCloudRow:
; Fill one BG map row at hl with the 4-tile cloud pattern starting at tile a.
	ld b, a
	ld c, 0
.loop
	ld a, c
	and %11
	add b
	ld [hli], a
	inc c
	ld a, c
	cp TILEMAP_WIDTH
	jr c, .loop
	ret

HoOhDescent_DrawStreaks:
; Scatter light streaks over the sky, in a pattern that wraps seamlessly.
	ld hl, vBGMap0
	ld b, 0 ; row
.row
	ld c, 0 ; column
.column
	ld a, c
	add a
	add c ; column * 3
	ld e, a
	ld a, b
	add a
	add a
	add b ; row * 5
	add e
	and %111
	ld a, HOOHDESCENT_BG_SKY
	jr nz, .got_tile
	ld a, HOOHDESCENT_BG_STREAK
.got_tile
	ld [hli], a
	inc c
	ld a, c
	cp TILEMAP_WIDTH
	jr c, .column
	inc b
	ld a, b
	cp TILEMAP_HEIGHT
	jr c, .row
	ret

HoOhDescent_ScrollClouds:
; Drift the clouds sideways, leaving the sky above them still.
	ld a, [wHoOhDescentTimer]
	and 1
	jr nz, .no_scroll
	ld hl, wHoOhDescentCloudScroll
	inc [hl]
.no_scroll
	ld a, [wHoOhDescentPanY]
	ld b, a
	ld a, 11 * TILE_WIDTH
	sub b
	jr nc, .got_sky_lines
	xor a
.got_sky_lines
	ld hl, wLYOverridesBackup
	and a
	jr z, .clouds
	push af
	ld c, a
	ld b, 0
	xor a
	call ByteFill
	pop af
.clouds
	cpl
	inc a
	add SCREEN_HEIGHT_PX ; lines left for the clouds
	ld c, a
	ld b, 0
	ld a, [wHoOhDescentCloudScroll]
	jp ByteFill

HoOhDescent_GetSway:
; Return a gentle 0-8 back-and-forth offset based on the timer.
	ld a, [wHoOhDescentTimer]
	srl a
	and %11111
	ld e, a
	ld d, 0
	ld hl, .Sine
	add hl, de
	ld a, [hl]
	ret

.Sine:
	db 4, 5, 6, 6, 7, 7, 8, 8, 8, 8, 8, 7, 7, 6, 6, 5
	db 4, 3, 2, 2, 1, 1, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3

HoOhDescent_CycleRainbow:
; Cycle the light's glow through the colors of the rainbow.
	ld a, [wJumptableIndex]
	cp 7 ; .FadeToWhite
	ret nc
	ld a, [wHoOhDescentTimer]
	and %11
	ret nz
	ld hl, wHoOhDescentRainbowIndex
	ld a, [hl]
	inc a
	cp (HoOhDescentRainbowColors.End - HoOhDescentRainbowColors) / COLOR_SIZE
	jr c, .got_index
	xor a
.got_index
	ld [hl], a
	add a
	ld e, a
	ld d, 0
	ld hl, HoOhDescentRainbowColors
	add hl, de
	ld a, [hli]
	ld d, [hl]
	ld e, a
	ld hl, wOBPals1 color 2
	ld a, e
	ld [hli], a
	ld [hl], d
	ld hl, wOBPals2 color 2
	ld a, e
	ld [hli], a
	ld [hl], d
	ld a, TRUE
	ldh [hCGBPalUpdate], a
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
; Leave a sparkle near the light, reusing the oldest sparkle slot.
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
	push hl
	call Random
	pop hl
	and %111
	ld b, a
	ld a, [wHoOhDescentOrbX]
	add b
	ld [hli], a
	push hl
	call Random
	pop hl
	and %111
	ld b, a
	ld a, [wHoOhDescentOrbY]
	add b
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
	swap a ; * 16
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

; the light
	ld a, [wHoOhDescentOrbY]
	and a
	jr z, .sparkles
	ld d, a
	ld a, [wHoOhDescentOrbX]
	and a
	jr z, .sparkles
	ld e, a
	ld a, [wHoOhDescentTimer]
	and %1000
	rrca ; 0 or 4
	ld c, a
	ld b, 0 ; attributes
	call .WriteSprite ; top left
	ld a, e
	add TILE_WIDTH
	ld e, a
	inc c
	call .WriteSprite ; top right
	ld a, d
	add TILE_WIDTH
	ld d, a
	ld a, e
	sub TILE_WIDTH
	ld e, a
	inc c
	call .WriteSprite ; bottom left
	ld a, e
	add TILE_WIDTH
	ld e, a
	inc c
	call .WriteSprite ; bottom right

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
	cp HOOHDESCENT_SPARKLE_LIFE / 2
	ld a, HOOHDESCENT_OB_SPARKLE_SMALL
	jr c, .got_sparkle_tile
	ld a, HOOHDESCENT_OB_SPARKLE_BIG
.got_sparkle_tile
	push af
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	pop af
	ld [hli], a
	ld [hl], 0 ; OBJ palette 0
	inc hl
.next_sparkle
	pop bc
	dec b
	jr nz, .sparkle_loop

; the leaves
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
	ld a, b
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
	ld a, 1 ; OBJ palette 1
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

.WriteSprite:
; Write OAM entry at hl: y = d, x = e, tile = c, attributes = b
	ld a, d
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, b
	ld [hli], a
	ret

HoOhDescentPalettes:
	RGB 15,23,31, 31,31,31, 22,26,31, 00,00,00 ; sky
	RGB 31,31,31, 31,31,31, 31,12,20, 31,24,06 ; light and sparkles
	RGB 31,31,31, 31,24,04, 31,12,02, 18,06,02 ; leaves

HoOhDescentFadePalettes:
; step 1
	RGB 19,25,31, 31,31,31, 24,27,31, 08,08,08
	RGB 31,31,31, 31,31,31, 31,17,23, 31,26,12
	RGB 31,31,31, 31,26,11, 31,17,09, 21,12,09
; step 2
	RGB 23,27,31, 31,31,31, 26,28,31, 16,16,16
	RGB 31,31,31, 31,31,31, 31,22,26, 31,28,18
	RGB 31,31,31, 31,28,18, 31,22,16, 24,18,16
; step 3
	RGB 27,29,31, 31,31,31, 29,30,31, 23,23,23
	RGB 31,31,31, 31,31,31, 31,26,28, 31,29,25
	RGB 31,31,31, 31,29,24, 31,26,24, 28,25,24
; step 4
	RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31
	RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31
	RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31

HoOhDescentRainbowColors:
	RGB 31,06,06 ; red
	RGB 31,18,04 ; orange
	RGB 31,29,06 ; yellow
	RGB 08,28,08 ; green
	RGB 06,16,31 ; blue
	RGB 22,08,30 ; violet
.End:

HoOhDescentBGGFX:
INCBIN "gfx/overworld/ho_oh_descent_bg.2bpp"
.End:

HoOhDescentOBGFX:
INCBIN "gfx/overworld/ho_oh_descent_ob.2bpp"
.End:
