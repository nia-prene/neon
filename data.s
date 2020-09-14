.segment "RAWDATA"
;raw data

paletteData:
	.byte $28, $08, $18, $37, $28, $05, $15, $35, $28, $0c, $06, $16, $28, $0c, $1c, $3c, $28, $08, $18, $37, $28, $05, $15, $35, $28, $0c, $06, $16, $1c, $0c, $1c, $3c
;people
people:
	.word odetteData, pepperData, reeseData, niaData

.DEFINE odette	0
odetteData:
	;palettes
	.byte $08, $28, $37;sprite
	.byte $08, $18, $37;portrait
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
	.byte $28 ;background color
	.byte $08, $18, $38;bg palettes
	.byte $08, $18, $38
	.byte $08, $18, $38
	.byte $00 ;to do objects
;scenes
scenes:;an array of pointers
	.word debugRoom
debugRoom:
	.byte cafe;place
	.byte odette, pepper, reese, nia, $ff


