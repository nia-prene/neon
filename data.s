.segment "RAWDATA"
;raw data

;default data
defaultPalette:
	.byte $08, $28, $37;odettesprite
	.byte $0c, $10, $36;white sprite
	;the two white sprites will be overwritten most often. I want to make sure POC are a part of this game by default.
	.byte $07, $16, $27;mixed sprite
	.byte $07, $18, $17;poc sprite
;people
people:
	.word odetteData, pepperData, reeseData, niaData

.DEFINE odette	0
odetteData:;this will be moved to ram eventually
	;palettes
	.byte $08, $28, $37;sprite
	.byte $08, $18, $37;portrait
	.byte $00, $00 
.DEFINE pepper	1
pepperData:
	;palettes
	.byte $06, $26, $36;sprite
	.byte $06, $16, $36;portrait
.DEFINE reese	2
reeseData:
	;palettes
	.byte $05, $15, $35;sprite
	.byte $05, $15, $35;portrait
.DEFINE nia	3	
niaData:
	;palettes
	.byte $03, $24, $35;sprite
	.byte $03, $24, $35;portrait


;places
places:
	.word cafeData
.DEFINE cafe	0
cafeData:
	.byte $08, $18, $38;bg palettes
	.byte $08, $18, $38
	.byte $08, $18, $38
	.byte $00 ;to do objects
;scenes
.DEFINE sunny	$37
.DEFINE twilight	$26
.DEFINE night	$00
.DEFINE rainy	$10
.DEFINE foggy	$20
scenes:;an array of pointers
	.word debugRoom
debugRoom:
	.byte twilight;time of day
	.byte cafe;place
	.byte odette, nia, reese, pepper, $ff


