	object_const_def
	const TINTOWERROOF_HO_OH
	const TINTOWERROOF_KIMONO_GIRL1
	const TINTOWERROOF_KIMONO_GIRL2
	const TINTOWERROOF_KIMONO_GIRL3
	const TINTOWERROOF_KIMONO_GIRL4
	const TINTOWERROOF_KIMONO_GIRL5

DEF NUM_TINTOWERROOF_KIMONO_GIRLS EQU 5

TinTowerRoof_MapScripts:
	def_scene_scripts
	scene_script TinTowerRoofHoOhEventScene, SCENE_TINTOWERROOF_HO_OH_EVENT
	scene_script TinTowerRoofNoopScene,      SCENE_TINTOWERROOF_NOOP

	def_callbacks
	callback MAPCALLBACK_OBJECTS, TinTowerRoofHoOhCallback

TinTowerRoofHoOhEventScene:
	checkevent EVENT_FOUGHT_HO_OH
	iftrue .Done
	checkitem RAINBOW_WING
	iffalse .Done
	sdefer TinTowerRoofHoOhEventScript
.Done:
	end

TinTowerRoofNoopScene:
	end

TinTowerRoofHoOhCallback:
	checkevent EVENT_FOUGHT_HO_OH
	iftrue .AfterHoOh
	checkitem RAINBOW_WING
	iffalse .NoAppear
	checkscene
	iftrue .HoOhHasDescended
	appear TINTOWERROOF_KIMONO_GIRL1
	appear TINTOWERROOF_KIMONO_GIRL2
	appear TINTOWERROOF_KIMONO_GIRL3
	appear TINTOWERROOF_KIMONO_GIRL4
	appear TINTOWERROOF_KIMONO_GIRL5
	disappear TINTOWERROOF_HO_OH
	endcallback

.HoOhHasDescended:
	appear TINTOWERROOF_HO_OH
	sjump .KimonoGirlsAfterDance

.AfterHoOh:
	disappear TINTOWERROOF_HO_OH
.KimonoGirlsAfterDance:
; Put the kimono girls back where their dance ended
	moveobject TINTOWERROOF_KIMONO_GIRL1,  7,  4
	moveobject TINTOWERROOF_KIMONO_GIRL2,  7,  7
	moveobject TINTOWERROOF_KIMONO_GIRL3, 10,  7
	moveobject TINTOWERROOF_KIMONO_GIRL4, 11,  7
	moveobject TINTOWERROOF_KIMONO_GIRL5, 11,  4
	appear TINTOWERROOF_KIMONO_GIRL1
	appear TINTOWERROOF_KIMONO_GIRL2
	appear TINTOWERROOF_KIMONO_GIRL3
	appear TINTOWERROOF_KIMONO_GIRL4
	appear TINTOWERROOF_KIMONO_GIRL5
	endcallback

.NoAppear:
	disappear TINTOWERROOF_HO_OH
	disappear TINTOWERROOF_KIMONO_GIRL1
	disappear TINTOWERROOF_KIMONO_GIRL2
	disappear TINTOWERROOF_KIMONO_GIRL3
	disappear TINTOWERROOF_KIMONO_GIRL4
	disappear TINTOWERROOF_KIMONO_GIRL5
	endcallback

TinTowerRoofHoOhEventScript:
	applymovement PLAYER, TinTowerRoofPlayerWalksToDancersMovement
	opentext
	writetext TinTowerRoofKimonoGirlWelcomeText
	waitbutton
	closetext
; A flash of light as the dance begins
	playsound SFX_SHINE
	special FadeOutToWhite
	special FadeInFromWhite
	playmusic MUSIC_KIMONO_ENCOUNTER
	callasm TinTowerRoofKimonoGirlsDanceAsm
	playsound SFX_HEAL_BELL
	waitsfx
	pause 30
	special FadeOutMusic
	special FadeOutToWhite
; Ho-Oh is already on the roof when the screen fades back in
	appear TINTOWERROOF_HO_OH
	special HoOhDescent
	pause 60
	cry HO_OH
	waitsfx
	special RestartMapMusic
	opentext
	writetext TinTowerRoofKimonoGirlHoOhHasComeText
	waitbutton
	closetext
	setscene SCENE_TINTOWERROOF_NOOP
	applymovement TINTOWERROOF_KIMONO_GIRL3, TinTowerRoofKimonoGirlStepsAsideMovement
	applymovement PLAYER, TinTowerRoofPlayerApproachesHoOhMovement
	sjump TinTowerHoOh

TinTowerRoofKimonoGirlsDanceAsm:
; Start every kimono girl's lane of TinTowerRoofDanceLanes at once,
; then make the script wait until the dance is over.
	ld a, BANK(TinTowerRoofDanceLanes)
	ld [wDanceMovementBank], a
	ld a, LOW(TinTowerRoofDanceLanes)
	ld [wDanceMovementPointer], a
	ld a, HIGH(TinTowerRoofDanceLanes)
	ld [wDanceMovementPointer + 1], a

	ld d, 0 ; lane
.loop
; object constants are one more than map object indexes (see GetScriptObject)
	ld a, d
	add TINTOWERROOF_KIMONO_GIRL1 - 1
	push de
	call CheckObjectVisibility
	pop de
	jr c, .next
	ld hl, OBJECT_MOVEMENT_TYPE
	add hl, bc
	ld [hl], SPRITEMOVEDATA_DANCE
	ld hl, OBJECT_MOVEMENT_INDEX
	add hl, bc
	ld [hl], 0
	ld hl, OBJECT_RANGE
	add hl, bc
	ld [hl], d
	ld hl, OBJECT_STEP_TYPE
	add hl, bc
	ld [hl], STEP_TYPE_RESET
	ld hl, OBJECT_FLAGS2
	add hl, bc
	res FROZEN_F, [hl]
.next
	inc d
	ld a, d
	cp NUM_TINTOWERROOF_KIMONO_GIRLS
	jr c, .loop

; Every lane lasts equally long, so the script resumes
; as soon as the first dancer reaches step_end.
	ld hl, wStateFlags
	set SCRIPTED_MOVEMENT_STATE_F, [hl]
	ld a, SCRIPT_WAIT_MOVEMENT
	ld [wScriptMode], a
	ret

TinTowerRoofPlayerWalksToDancersMovement:
; up the ladder to the gap in the railing
	step UP
	step UP
	step UP
	step UP
	step UP
	step_end

TinTowerRoofKimonoGirlStepsAsideMovement:
	step RIGHT
	turn_head LEFT
	step_end

TinTowerRoofPlayerApproachesHoOhMovement:
	step UP
	step_end

TinTowerRoofDanceLanes:
; Lanes for kimono girls 1-5 (left to right, starting at y=7), generated so that
; every lane lasts exactly as long (712 frames). The girls take the four corners
; and the centre below the spire, then spin, sway, and swap places four times.
	dw .Lane1
	dw .Lane2
	dw .Lane3
	dw .Lane4
	dw .Lane5

.Lane1:
	step UP
	step UP
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in RIGHT
	turn_in LEFT
	turn_in DOWN
	turn_in UP
	step RIGHT
	step DOWN
	step DOWN
	step DOWN
	step LEFT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in RIGHT
	turn_in LEFT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in RIGHT
	turn_in LEFT
	turn_in DOWN
	turn_in UP
	step RIGHT
	step DOWN
	step DOWN
	step DOWN
	step LEFT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in RIGHT
	turn_in LEFT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in RIGHT
	turn_in LEFT
	turn_in DOWN
	turn_in UP
	step DOWN
	step UP
	turn_head DOWN
	step_sleep 32
	step_end

.Lane2:
	step LEFT
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in RIGHT
	turn_in LEFT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in RIGHT
	turn_in LEFT
	turn_in DOWN
	turn_in UP
	step RIGHT
	step DOWN
	step DOWN
	step DOWN
	step LEFT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in RIGHT
	turn_in LEFT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in RIGHT
	turn_in LEFT
	turn_in DOWN
	turn_in UP
	step RIGHT
	step DOWN
	step DOWN
	step DOWN
	step LEFT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in RIGHT
	turn_in LEFT
	step UP
	step DOWN
	turn_head DOWN
	step_sleep 32
	step_end

.Lane3:
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in RIGHT
	turn_in LEFT
	step DOWN
	step_sleep 24
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in RIGHT
	turn_in LEFT
	step DOWN
	step_sleep 24
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in RIGHT
	turn_in LEFT
	step DOWN
	step_sleep 24
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in RIGHT
	turn_in LEFT
	step DOWN
	step_sleep 24
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in RIGHT
	turn_in LEFT
	step DOWN
	step_sleep 8
	turn_head DOWN
	step_sleep 32
	step_end

.Lane4:
	step RIGHT
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in LEFT
	turn_in RIGHT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in DOWN
	turn_in UP
	step LEFT
	step DOWN
	step DOWN
	step DOWN
	step RIGHT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in LEFT
	turn_in RIGHT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in DOWN
	turn_in UP
	step LEFT
	step DOWN
	step DOWN
	step DOWN
	step RIGHT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in LEFT
	turn_in RIGHT
	step UP
	step DOWN
	turn_head DOWN
	step_sleep 32
	step_end

.Lane5:
	step UP
	step UP
	step UP
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in DOWN
	turn_in UP
	step LEFT
	step DOWN
	step DOWN
	step DOWN
	step RIGHT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in LEFT
	turn_in RIGHT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in DOWN
	turn_in UP
	step LEFT
	step DOWN
	step DOWN
	step DOWN
	step RIGHT
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_in UP
	turn_in DOWN
	turn_in LEFT
	turn_in RIGHT
	step UP
	step UP
	step UP
	step_sleep 16
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_step DOWN
	step_sleep 4
	turn_step LEFT
	step_sleep 4
	turn_step UP
	step_sleep 4
	turn_step RIGHT
	step_sleep 4
	turn_in LEFT
	turn_in RIGHT
	turn_in DOWN
	turn_in UP
	step DOWN
	step UP
	turn_head DOWN
	step_sleep 32
	step_end

TinTowerHoOh:
	faceplayer
	opentext
	writetext HoOhText
	cry HO_OH
	pause 15
	closetext
; Ho-Oh's cry fills the roof with light
	playsound SFX_FLASH
	special FadeOutToWhite
	special FadeInFromWhite
	setevent EVENT_FOUGHT_HO_OH
	loadvar VAR_BATTLETYPE, BATTLETYPE_FORCEITEM
	loadwildmon HO_OH, 60
	startbattle
	disappear TINTOWERROOF_HO_OH
	reloadmapafterbattle
	setevent EVENT_SET_WHEN_FOUGHT_HO_OH
	end

TinTowerRoofKimonoGirlScript:
	faceplayer
	opentext
	checkevent EVENT_FOUGHT_HO_OH
	iftrue .AfterHoOh
	writetext TinTowerRoofKimonoGirlGoOnText
	waitbutton
	closetext
	end

.AfterHoOh:
	writetext TinTowerRoofKimonoGirlAfterHoOhText
	waitbutton
	closetext
	end

HoOhText:
	text "Shaoooh!"
	done

TinTowerRoofKimonoGirlWelcomeText:
	text "Welcome. We had a"
	line "feeling you would"
	cont "come today."

	para "Since long ago, we"
	line "have trained in a"
	cont "dance of welcome."

	para "When the bells of"
	line "the tower ring out"

	para "and our dance is"
	line "done, the bird of"
	cont "rainbow light will"

	para "come down from the"
	line "sky once more."

	para "Please, watch"
	line "closely."
	done

TinTowerRoofKimonoGirlHoOhHasComeText:
	text "It came… Ho-Oh,"
	line "keeper of the sky!"

	para "Countless people"
	line "have climbed this"

	para "tower hoping to"
	line "meet it, and none"
	cont "ever did."

	para "But it chose to"
	line "come down for you."

	para "Go on, <PLAYER>."
	line "It has been"
	cont "waiting."
	done

TinTowerRoofKimonoGirlGoOnText:
	text "Ho-Oh is waiting"
	line "for you."
	done

TinTowerRoofKimonoGirlAfterHoOhText:
	text "We will never"
	line "forget the day"

	para "Ho-Oh came down"
	line "to this tower."
	done

TinTowerRoof_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  9, 13, TIN_TOWER_9F, 4

	def_coord_events

	def_bg_events

	def_object_events
	object_event  9,  6, SPRITE_HO_OH, SPRITEMOVEDATA_POKEMON, 0, 0, -1, -1, PAL_NPC_RED, OBJECTTYPE_SCRIPT, 0, TinTowerHoOh, EVENT_TIN_TOWER_ROOF_HO_OH
	object_event  7,  7, SPRITE_KIMONO_GIRL, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_RED, OBJECTTYPE_SCRIPT, 0, TinTowerRoofKimonoGirlScript, EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS
	object_event  8,  7, SPRITE_KIMONO_GIRL, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_BLUE, OBJECTTYPE_SCRIPT, 0, TinTowerRoofKimonoGirlScript, EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS
	object_event  9,  7, SPRITE_KIMONO_GIRL, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_PINK, OBJECTTYPE_SCRIPT, 0, TinTowerRoofKimonoGirlScript, EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS
	object_event 10,  7, SPRITE_KIMONO_GIRL, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, TinTowerRoofKimonoGirlScript, EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS
	object_event 11,  7, SPRITE_KIMONO_GIRL, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_BROWN, OBJECTTYPE_SCRIPT, 0, TinTowerRoofKimonoGirlScript, EVENT_TIN_TOWER_ROOF_KIMONO_GIRLS
