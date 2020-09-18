.segment "RAWDATA"
;raw data

;default data
defaultPalette:
	.byte $00, $08, $28, $37;odettesprite
	.byte $00, $0c, $10, $36;white sprite
	;the two white sprites will be overwritten most often. I want to make sure POC are a part of this game by default.
	.byte $00, $07, $16, $27;mixed sprite
	.byte $00, $07, $18, $17;poc sprite
;people
peoplePalettes:
	.word odetteData, pepperData, reeseData, niaData

.DEFINE odette	0
odetteData:;this will be moved to ram eventually
	;palettes
	.byte $00, $08, $28, $37;sprite
	.byte $00, $08, $18, $37;portrait
.DEFINE pepper	1
pepperData:
	;palettes
	.byte $00, $06, $26, $36;sprite
	.byte $00, $06, $16, $36;portrait
.DEFINE reese	2
reeseData:
	;palettes
	.byte $00, $05, $15, $35;sprite
	.byte $00, $05, $15, $35;portrait
.DEFINE nia	3	
niaData:
	;palettes
	.byte $00, $03, $24, $35;sprite
	.byte $00, $03, $24, $35;portrait

;sprites
spriteData:
	.word odette1
odette1:
	;head
	.byte $00, $00, $00, $00
	.byte $00, $02, $00, $08
	.byte $00, $00, $40, $0f
	;body
	.byte $10, $04, $00, $00
	.byte $10, $06, $00, $08
	.byte $10, $08, $00, $10
	;legs
	.byte $20, $0a, $00, $00
	.byte $20, $0c, $00, $08
	.byte $20, $0a, $40, $0f
	.byte $ff
;places
places:
	.word cafeData
.DEFINE cafe	0
cafeData:
	.byte $00, $08, $18, $38;bg palettes
	.byte $00, $08, $18, $38
	.byte $00, $08, $18, $38
	;todo objects
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
	.byte odette, reese, pepper, nia, $ff, $00, $00, $00, $00, $ff


