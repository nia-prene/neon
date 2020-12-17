.segment "RAWDATA"
;raw data

;default data
defaultPalette:
	.byte $00, $08, $28, $37;odettesprite
	.byte $00, $0c, $10, $36
	.byte $00, $07, $16, $27
	.byte $00, $07, $18, $17

;people
peoplePalettes:
	.word odetteData, pepperData, reeseData, niaData

.DEFINE odette	0
odetteData:;this will be moved to ram eventually
	;palettes
	.byte $00, $08, $28, $37;sprite
	.byte $00, $08, $18, $37;portrait
pepper = 1
pepperData:
	;palettes
	.byte $00, $06, $26, $36;sprite
	.byte $00, $06, $16, $36;portrait
reese = 2
reeseData:
	;palettes
	.byte $00, $05, $15, $35;sprite
	.byte $00, $05, $15, $35;portrait
nia = 3	
niaData:
	;palettes
	.byte $00, $03, $24, $35;sprite
	.byte $00, $03, $24, $35;portrait


;sprites
odetteFront = 0

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


;sprite locations
frontDoor = 0
spriteLocations:
	.word cafeFrontDoor, window, table, chair

cafeFrontDoor:
	.byte 222, 50
window:
	.byte 123, 100
table:
	.byte 33, 55
chair:
	.byte 66, 200

;;;;;;;;;;;;;;;
;;;;;tiles;;;;;
;;;;;;;;;;;;;;;
;;;16x16;;;
;;;;;;;;;;;
topLeft16:
	.byte $00, $01, $02, $03, $02, $02, $02, $01, $02, $02, $00, $05, $03, $13, $06, $02
	.byte $11, $02, $00, $0b, $00, $00, $09, $15, $00, $00, $02, $0e, $0e, $0e, $13, $13
	.byte $10, $00, $01, $03, $18, $03, $02, $0d, $02, $00, $0d, $0b, $00, $03, $03, $06
	.byte $0d, $03, $09, $02, $15, $1c, $02, $03, $03, $1d
bottomLeft16:
	.byte $00, $01, $02, $03, $02, $02, $07, $07, $11, $00, $05, $03, $01, $15, $0c, $02
	.byte $03, $00, $00, $02, $00, $09, $01, $03, $07, $07, $03, $0e, $0e, $0e, $13, $15
	.byte $00, $16, $01, $03, $01, $03, $06, $01, $11, $06, $1b, $11, $06, $03, $03, $02
	.byte $01, $07, $1f, $13, $03, $1f, $03, $03, $07, $1e
topRight16:
	.byte $00, $01, $02, $03, $02, $00, $00, $01, $02, $02, $00, $00, $08, $14, $06, $0a
	.byte $11, $02, $02, $02, $00, $04, $03, $12, $00, $02, $02, $10, $00, $01, $03, $03
	.byte $0f, $0f, $0f, $17, $03, $12, $00, $0d, $0a, $00, $0d, $02, $02, $12, $14, $06
	.byte $0d, $03, $1c, $02, $03, $03, $02, $02, $02, $08
bottomRight16:
	.byte $00, $01, $02, $03, $00, $00, $07, $07, $11, $00, $00, $08, $01, $03, $0c, $02
	.byte $03, $02, $02, $02, $04, $03, $01, $14, $07, $07, $03, $00, $01, $01, $03, $03
	.byte $0f, $0f, $0f, $19, $03, $14, $06, $1a, $11, $06, $01, $11, $06, $12, $03, $02
	.byte $01, $07, $1e, $03, $03, $1e, $02, $02, $07, $1f
collisionState:
;;;;;;;;;;;
;;;32x32;;;
;;;;;;;;;;;
topLeft32:
	.byte $00, $01, $02, $03, $04, $06, $01, $03, $09, $09, $00, $0f, $14, $16, $0a, $0c
	.byte $05, $13, $18, $05, $14, $1a, $03, $1c, $1e, $23, $03, $26, $28, $29, $29, $1f
	.byte $03, $03, $02, $10, $1a, $03, $31, $30
bottomLeft32:
	.byte $00, $01, $02, $03, $05, $07, $08, $03, $00, $00, $0e, $10, $15, $17, $0b, $0d
	.byte $0e, $10, $07, $0e, $15, $03, $1b, $1d, $1f, $03, $03, $27, $03, $27, $27, $03
	.byte $03, $2f, $30, $03, $03, $03, $35, $1a
topRight32:
	.byte $00, $01, $02, $03, $09, $0a, $0c, $03, $09, $11, $12, $13, $18, $01, $00, $0f
	.byte $14, $16, $0a, $00, $19, $1a, $03, $21, $03, $24, $25, $29, $2b, $29, $2c, $2d
	.byte $2e, $31, $30, $34, $36, $37, $38, $30
bottomRight32:
	.byte $00, $01, $02, $03, $00, $0b, $0d, $03, $00, $12, $0e, $10, $07, $08, $0e, $10
	.byte $15, $17, $0b, $0e, $07, $03, $20, $22, $03, $03, $03, $2a, $03, $2a, $2a, $2d
	.byte $03, $32, $33, $03, $37, $37, $39, $1a
tileAttributeByte:
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%01010000,%01010101,%00000000,%00000000,%00000000,%01010101,%00000000,%01010000,%00000000,%01010100
	.byte %00000000,%01010001,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%01010101,%00000000,%01010101,%00000000,%01010101,%00000000,%00000000,%01010101
	.byte %01010101, %00000000,%01000000,%01010101,%00000000,%00000000,%00000000,%01010000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
;;;;;;;;;;;
;;;64x64;;;
;;;;;;;;;;;
topLeft64:
	.byte $00, $01, $02, $03, $01, $04, $06, $07, $01, $08, $0d, $01, $04, $11, $01, $04
	.byte $0b, $01, $16, $18, $04, $1c, $09, $1c, $01, $03, $22
bottomLeft64:
	.byte $00, $01, $02, $03, $04, $05, $07, $07, $09, $0c, $07, $08, $10, $07, $08, $13
	.byte $07, $15, $17, $07, $1b, $07, $1e, $07, $15, $21, $23
topRight64:
	.byte $00, $01, $02, $03, $01, $09, $0b, $07, $01, $08, $0f, $01, $08, $06, $01, $09
	.byte $0d, $01, $03, $1a, $08, $1c, $03, $1f, $01, $25, $27
bottomRight64:
	.byte $00, $01, $02, $03, $08, $0a, $07, $07, $08, $0e, $07, $04, $12, $07, $09, $14
	.byte $07, $15, $19, $07, $1d, $07, $03, $20, $24, $26, $07
;;;;;;;;;;;;;
;;;128x128;;;
;;;;;;;;;;;;;
topLeft128:
	.byte $00, $01, $02, $03, $04, $06, $0b, $0d, $11, $13, $11, $17
bottomLeft128:
	.byte $00, $01, $02, $03, $05, $07, $0c, $07, $12, $07, $16, $07
topRight128:
	.byte $00, $01, $02, $03, $08, $0a, $0e, $10, $11, $15, $18, $1a
bottomRight128:
	.byte $00, $01, $02, $03, $09, $07, $0f, $07, $14, $07, $19, $07
;;;;;;;;;;;;;;
;;;screens;;;;
;;;;;;;;;;;;;;
;constants;
;;;;;;;;;;;
CAFESCREEN1 = $04
CAFESCREEN2 = $05
CAFESCREEN3 = $06
CAFESCREEN4 = $07
topHalfScreen:
	.byte $00, $01, $02, $03, $04, $06, $08, $0a
bottomHalfScreen:
	.byte $00, $01, $02, $03, $05, $07, $09, $0b
nameTableConversion:
	.dbyt $2000, $2080, $2100, $2180, $2200, $2280, $2300, $2380, $2004, $2084, $2104, $2184, $2204, $2284, $2304, $2384, $2008, $2088, $2108, $2188, $2208, $2288, $2308, $2388, $200c, $208c, $210c, $218c, $220c, $228c, $230c, $238c, $2010, $2090, $2110, $2190, $2210, $2290, $2310, $2390, $2014, $2094, $2114, $2194, $2214, $2294, $2314, $2394, $2018, $2098, $2118, $2198, $2218, $2298, $2318, $2398, $201c, $209c, $211c, $219c, $221c, $229c, $231c, $239c
	.dbyt $2400, $2480, $2500, $2580, $2600, $2680, $2700, $2780, $2404, $2484, $2504, $2584, $2604, $2684, $2704, $2784, $2408, $2488, $2508, $2588, $2608, $2688, $2708, $2788, $240c, $248c, $250c, $258c, $260c, $268c, $270c, $278c, $2410, $2490, $2510, $2590, $2610, $2690, $2710, $2790, $2414, $2494, $2514, $2594, $2614, $2694, $2714, $2794, $2418, $2498, $2518, $2598, $2618, $2698, $2718, $2798, $241c, $249c, $251c, $259c, $261c, $269c, $271c, $279c
attributeTableConversion:
	.dbyt $23c0, $23c8, $23d0, $23d8, $23e0, $23e8, $23f0, $23f8, $23c1, $23c9, $23d1, $23d9, $23e1, $23e9, $23f1, $23f9, $23c2, $23ca, $23d2, $23da, $23e2, $23ea, $23f2, $23fa, $23c3, $23cb, $23d3, $23db, $23e3, $23eb, $23f3, $23fb, $23c4, $23cc, $23d4, $23dc, $23e4, $23ec, $23f4, $23fc, $23c5, $23cd, $23d5, $23dd, $23e5, $23ed, $23f5, $23fd, $23c6, $23ce, $23d6, $23de, $23e6, $23ee, $23f6, $23fe, $23c7, $23cf, $23d7, $23df, $23e7, $23ef, $23f7, $23ff
	.dbyt $27c0, $27c8, $27d0, $27d8, $27e0, $27e8, $27f0, $27f8, $27c1, $27c9, $27d1, $27d9, $27e1, $27e9, $27f1, $27f9, $27c2, $27ca, $27d2, $27da, $27e2, $27ea, $27f2, $27fa, $27c3, $27cb, $27d3, $27db, $27e3, $27eb, $27f3, $27fb, $27c4, $27cc, $27d4, $27dc, $27e4, $27ec, $27f4, $27fc, $27c5, $27cd, $27d5, $27dd, $27e5, $27ed, $27f5, $27fd, $27c6, $27ce, $27d6, $27de, $27e6, $27ee, $27f6, $27fe, $27c7, $27cf, $27d7, $27df, $27e7, $27ef, $27f7, $27ff
;;;;;;;;;;;;;;;;
;;;;;places;;;;;
;;;;;;;;;;;;;;;;
;;;constants;;;;
;;;;;;;;;;;;;;;;;;;
;pointer positions;
CAFE = 0
;array positions;
PLACEPALETTES = 0
SCREENS = 12
;;;;;;;;;;;;
;place data;
;;;;;;;;;;;;
places:
	.word cafeData
cafeData:
	;palettes
	.byte $00, $07, $15, $35
	.byte $00, $07, $10, $36
	.byte $00, $07, $36, $10
	;screens
	.byte CAFESCREEN1, CAFESCREEN2, CAFESCREEN3, CAFESCREEN4

;;;;;;;;;;;;;;;;
;;;;;scenes;;;;; 
;;;;;;;;;;;;;;;;
;;;constants;;;
;;;;;;;;;;;;;;;;;
;array positions;
;;;;;;;;;;;;;;;;;
TIMEOFDAY = $00
LOCATION = $01
PEOPLEPALETTES = $02;null terminated
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;background weather (color);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUNNY = $31
TWILIGHT = $26
NIGHT = $01
RAINY = $00

scenes:;an array of pointers
	.word debugRoom

debugRoom:
	;time of day
	.byte SUNNY
	;where it is
	.byte CAFE

