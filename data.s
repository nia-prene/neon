.segment "RAWDATA"
;;;;;;;;;;;;
;;;scenes;;; 
;;;;;;;;;;;;
;tile;
;;;;;;
screenTile:
;stored as screen number
	.byte $0
;;;;;;;;;;
;palettes;
;;;;;;;;;;
;sprite palette 0 is player
;3rd palettes are effects
sceneBackgroundColor:
;stored as nes color number
	.byte $31
backgroundPalette0:
;stored as palette: collection index
	.byte BRIDGE_PALETTE
backgroundPalette1:
;stored as palette: collection index
	.byte BRIDGE_PALETTE
backgroundPalette2:
;stored as palette: collection index
	.byte BRIDGE_PALETTE
spritePalette1:
	.byte REESE_PALETTE
;stored as palette: collection index
spritePalette2:
;stored as palette: collection index
	.byte REESE_PALETTE

;;;;;;;;;;;
;;;tiles;;;
;;;;;;;;;;;
;screens;
;256x256;
;;;;;;;;;
topLeft256:
	.byte $00
bottomLeft256:
	.byte $04
topRight256:
	.byte $00
bottomRight256:
	.byte $04
;;;;;;;;;
;128x128;
;;;;;;;;;
topLeft128:
	.byte $00, $01, $02, $03, $00
bottomLeft128:
	.byte $00, $01, $02, $03, $04
topRight128:
	.byte $00, $01, $02, $03, $00
bottomRight128:
	.byte $00, $01, $02, $03, $04
;;;;;;;
;64x64;
;;;;;;;
topLeft64:
	.byte $00, $01, $02, $03, $04
bottomLeft64:
	.byte $00, $01, $02, $03, $00
topRight64:
	.byte $00, $01, $02, $03, $04
bottomRight64:
	.byte $00, $01, $02, $03, $00
;;;;;;;
;32x32;
;;;;;;;
topLeft32:
	.byte $00, $01, $02, $03, $04
bottomLeft32:
	.byte $00, $01, $02, $03, $05
topRight32:
	.byte $00, $01, $02, $03, $04
bottomRight32:
	.byte $00, $01, $02, $03, $05
collisionState:
	.byte %00000000, %00000000, %00000000, %00000000, %11111111
tileAttributeByte:
		.byte $00, $00, $00, $00, $00, $00, $00, $00
;;;;;;;
;16x16;
;;;;;;;
topLeft16:
	.byte $00, $01, $02, $03, $07, $08
bottomLeft16:
	.byte $00, $01, $02, $03, $09, $05
topRight16:
	.byte $00, $01, $02, $03, $07, $02
bottomRight16:
	.byte $00, $01, $02, $03, $0a, $05

nameTableConversion:
	.dbyt $2000, $2080, $2100, $2180, $2200, $2280, $2300, $2380, $2004, $2084, $2104, $2184, $2204, $2284, $2304, $2384, $2008, $2088, $2108, $2188, $2208, $2288, $2308, $2388, $200c, $208c, $210c, $218c, $220c, $228c, $230c, $238c, $2010, $2090, $2110, $2190, $2210, $2290, $2310, $2390, $2014, $2094, $2114, $2194, $2214, $2294, $2314, $2394, $2018, $2098, $2118, $2198, $2218, $2298, $2318, $2398, $201c, $209c, $211c, $219c, $221c, $229c, $231c, $239c
	.dbyt $2400, $2480, $2500, $2580, $2600, $2680, $2700, $2780, $2404, $2484, $2504, $2584, $2604, $2684, $2704, $2784, $2408, $2488, $2508, $2588, $2608, $2688, $2708, $2788, $240c, $248c, $250c, $258c, $260c, $268c, $270c, $278c, $2410, $2490, $2510, $2590, $2610, $2690, $2710, $2790, $2414, $2494, $2514, $2594, $2614, $2694, $2714, $2794, $2418, $2498, $2518, $2598, $2618, $2698, $2718, $2798, $241c, $249c, $251c, $259c, $261c, $269c, $271c, $279c
attributeTableConversion:
	.dbyt $23c0, $23c8, $23d0, $23d8, $23e0, $23e8, $23f0, $23f8, $23c1, $23c9, $23d1, $23d9, $23e1, $23e9, $23f1, $23f9, $23c2, $23ca, $23d2, $23da, $23e2, $23ea, $23f2, $23fa, $23c3, $23cb, $23d3, $23db, $23e3, $23eb, $23f3, $23fb, $23c4, $23cc, $23d4, $23dc, $23e4, $23ec, $23f4, $23fc, $23c5, $23cd, $23d5, $23dd, $23e5, $23ed, $23f5, $23fd, $23c6, $23ce, $23d6, $23de, $23e6, $23ee, $23f6, $23fe, $23c7, $23cf, $23d7, $23df, $23e7, $23ef, $23f7, $23ff
	.dbyt $27c0, $27c8, $27d0, $27d8, $27e0, $27e8, $27f0, $27f8, $27c1, $27c9, $27d1, $27d9, $27e1, $27e9, $27f1, $27f9, $27c2, $27ca, $27d2, $27da, $27e2, $27ea, $27f2, $27fa, $27c3, $27cb, $27d3, $27db, $27e3, $27eb, $27f3, $27fb, $27c4, $27cc, $27d4, $27dc, $27e4, $27ec, $27f4, $27fc, $27c5, $27cd, $27d5, $27dd, $27e5, $27ed, $27f5, $27fd, $27c6, $27ce, $27d6, $27de, $27e6, $27ee, $27f6, $27fe, $27c7, $27cf, $27d7, $27df, $27e7, $27ef, $27f7, $27ff
;;;;;;;;;;;;;
;;;sprites;;;
;;;;;;;;;;;;;;;;
;sprite objects;
;;;;;;;;;;;;;;;;
REESE_OBJECT = 0
inputMethod:
	.byte CONTROLLER_2
;metatile collections as states
spriteWidth:
	.byte 03
spriteHeight:
	.byte 04
spriteTotal:
	.byte 12
spriteState0:
	.byte REESE_IDLE_0
spriteState1:
spriteState2:
spriteState3:
spriteState4:
spriteState5:
;sprite data;
;number, attribute
;;;;;;;;;;;;
;metasprite;
;;;;;;;;;;;;
REESE_IDLE_0= 0
numberOfTiles:
	.byte 12 
;76543210
;||||||||
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
spriteTile0:
	.byte $01 
spriteAttribute0:
	.byte %00000000
spriteTile1:
	.byte $01
spriteAttribute1:
	.byte %01000000
spriteTile2:
	.byte $00
spriteAttribute2:
	.byte %00000000
spriteTile3:
	.byte $02 
spriteAttribute3:
	.byte %00000000
spriteTile4:
	.byte $03
spriteAttribute4:
	.byte %00000000
spriteTile5:
	.byte $00
spriteAttribute5:
	.byte %00000000
spriteTile6:
	.byte $04
spriteAttribute6:
	.byte %00000000
spriteTile7:
	.byte $05
spriteAttribute7:
	.byte %00000000
spriteTile8:
	.byte $00
spriteAttribute8:
	.byte %00000000
spriteTile9:
	.byte $06
spriteAttribute9:
	.byte %00000000
spriteTile10:
	.byte $07
spriteAttribute10:
	.byte %00000000
spriteTile11:
	.byte $00
spriteAttribute11:
	.byte %00000000
;hitboxes
hitBoxX1:
	.byte $05
hitBoxX2:
hitBoxY1:
hitBoxY2:
;;;;;;;;;;;;;;
;;;palettes;;;
;;;;;;;;;;;;;;
REESE_PALETTE = 0
BRIDGE_PALETTE = 1
paletteColor1:
	.byte $07, $1c
paletteColor2:
	.byte $25, $2c
paletteColor3:
	.byte $35, $3c
;;;;;;;;;;;;;;;
;sprite inputs;
;;;;;;;;;;;;;;;
spriteInputsH:
	.byte >controller1Input
	.byte >controller2Input
spriteInputsL:
	.byte <controller1Input-1 
	.byte <controller2Input-1
CONTROLLER_1 = 0
CONTROLLER_2 = 1
controller1Input:
	jsr testLoop
    lda #$01;strobe register
    sta JOY1
    lda #$00
    sta JOY1
    ldx #08
@loop:
    pha;save result
    lda JOY1
    lsr;move 0 bit to carry
    pla;get result
    rol;move carry to bit 7
    dex
    bne @loop
	ldy objectToUpdate
	lda #$55
	sta inputs,y
    rts

controller2Input:
	jsr testLoop
    lda #$01;strobe register
    sta JOY1
    lda #$00
    sta JOY1
    ldx #08
@loop:
    pha;save result
    lda JOY2
    lsr;move 0 bit to carry
    pla;get result
    rol;move carry to bit 7
    dex
    bne @loop
	ldx objectToUpdate
	sta inputs,x
    rts
;;;;;;;;;;;;;;;;;
;sprite behavior;
;;;;;;;;;;;;;;;;;
PLAYER_BEHAVIOR = 0
spriteBehaviorH:
	.byte >playerBehavior
spriteBehaviorL:
	.byte <playerBehavior-1
playerBehavior:
	rts
