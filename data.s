.segment "RAWDATA"

leftRail:
	.byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01 

;;;;;;;;;;;;;;;
;;;romScenes;;; 
;;;;;;;;;;;;;;;
;unsigned screentile
;unsigned paletteCollection
screenTile:
	.byte $0
paletteCollection:
	.byte OASIS_PALETTE

;;;;;;;;;;;
;;;tiles;;;
;;;;;;;;;;;
;screens;
;256x256;
;;;;;;;;;
topLeft256:
	.byte $04
bottomLeft256:
	.byte $04
topRight256:
	.byte $04
bottomRight256:
	.byte $04
;;;;;;;;;
;128x128;
;;;;;;;;;
topLeft128:
	.byte $00, $01, $02, $03, $04 
bottomLeft128:
	.byte $00, $01, $02, $03, $04
topRight128:
	.byte $00, $01, $02, $03, $04
bottomRight128:
	.byte $00, $01, $02, $03, $04
;;;;;;;
;64x64;
;;;;;;;
topLeft64:
	.byte $00, $01, $02, $03, $04 
bottomLeft64:
	.byte $00, $01, $02, $03, $06
topRight64:
	.byte $00, $01, $02, $03, $05
bottomRight64:
	.byte $00, $01, $02, $03, $07
;;;;;;;
;32x32;
;;;;;;;
topLeft32:
	.byte $00, $01, $02, $03, $03, $05, $09, $0a
bottomLeft32:
	.byte $00, $01, $02, $03, $06, $07, $03, $0d
topRight32:
	.byte $00, $01, $02, $03, $04, $03, $02, $0b
bottomRight32:
	.byte $00, $01, $02, $03, $02, $08, $0c, $03
collisionTopLeft:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
collisionBottomLeft:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
collisionTopRight:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
collisionBottomRight:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
tileAttributeByte:
	.byte %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010
;;;;;;;
;16x16;
;;;;;;;
topLeft16:
	.byte $00, $01, $02, $03, $03, $03, $03, $02, $09, $03, $02, $0f, $14, $16
bottomLeft16:
	.byte $00, $01, $02, $03, $04, $06, $03, $02, $0c, $03, $11, $13, $03, $03
topRight16:
	.byte $00, $01, $02, $03, $03, $03, $08, $02, $03, $0d, $0e, $03, $15, $17
bottomRight16:
	.byte $00, $01, $02, $03, $05, $07, $0a, $0b, $03, $10, $12, $03, $03, $03
;;;;;;;;;;;;;;
;;;palettes;;;
;;;;;;;;;;;;;;
;collections;
;;;;;;;;;;;;;
OASIS_PALETTE = 0
palette0:
	.byte OASIS0
palette1:
	.byte OASIS1
palette2:
	.byte OASIS2
palette3:
	.byte OASIS3
PLAYER_PALETTE= 0
COIN_PALETTE = 1
OASIS0 = 2
OASIS1 = 3
OASIS2 = 4
OASIS3 = 5
romColor1:
	.byte $05, $07, $16, $05, $26, $07
romColor2:
	.byte $25, $27, $26, $06, $34, $0b
romColor3:
	.byte $35, $37, $31, $07, $2c, $1b

;;;;;;;;;;;;;
;;;sprites;;;
;;;;;;;;;;;;;;;;
;sprite objects;
;;;;;;;;;;;;;;;;
PLAYER_OBJECT = 0
COIN_0 = 1
romSpriteTotal:
	.byte 04, 02
romSpriteWidth:
	.byte 02, 02
romSpriteHeight:
	.byte 02, 02
romHitboxY1:
	.byte 02, 02
romHitboxY2:
	.byte 06, 14
romBehaviorH:
	.byte >playerBehavior
	.byte >coinBehavior0
romBehaviorL:
	.byte <playerBehavior-1
	.byte <coinBehavior0-1
;;;;;;;;;;;;;
;metasprites;
;;;;;;;;;;;;;
;tile, attribute
;76543210
;||||||||
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
PLAYER_IDLE = 0
COIN_FRAME_0 = 1
COIN_FRAME_1 = 2
COIN_FRAME_2 = 3
COIN_FRAME_3 = 4

spriteTile0:
	.byte $00, $40, $42, $46, $44
spriteAttribute0:
	.byte %00000000, %00000001, %00000001, %00000001, %01000001
spriteTile1:
	.byte $02, $40, $44, $46, $42
spriteAttribute1:
	.byte %00000000, %01000001, %00000001, %01000001, %01000001
spriteTile2:
	.byte $04
spriteAttribute2:
	.byte %00000000
spriteTile3:
	.byte $06 
spriteAttribute3:
	.byte %00000000
;;;;;;;;;;;;;;;;
;;;animations;;;
;;;;;;;;;;;;;;;;
playerIdleAnimation:
playerLeftAnimation:
playerRightAnimation:
coinAnimation:
	.byte COIN_FRAME_0, COIN_FRAME_1, COIN_FRAME_2, COIN_FRAME_3 
;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;lookup tables;;;
;;;;;;;;;;;;;;;;;;;

nameTableConversionH:
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $24, $24, $25, $25, $26, $26, $27, $27, $24, $24, $25, $25, $26, $26, $27, $27
	.byte $24, $24, $25, $25, $26, $26, $27, $27, $24, $24, $25, $25, $26, $26, $27, $27
	.byte $24, $24, $25, $25, $26, $26, $27, $27, $24, $24, $25, $25, $26, $26, $27, $27
	.byte $24, $24, $25, $25, $26, $26, $27, $27, $24, $24, $25, $25, $26, $26, $27, $27
nameTableConversionL:
	.byte $00, $80, $00, $80, $00, $80, $00, $80, $04, $84, $04, $84, $04, $84, $04, $84 
	.byte $08, $88, $08, $88, $08, $88, $08, $88, $0c, $8c, $0c, $8c, $0c, $8c, $0c, $8c 
	.byte $10, $90, $10, $90, $10, $90, $10, $90, $14, $94, $14, $94, $14, $94, $14, $94 
	.byte $18, $98, $18, $98, $18, $98, $18, $98, $1c, $9c, $1c, $9c, $1c, $9c, $1c, $9c
	.byte $00, $80, $00, $80, $00, $80, $00, $80, $04, $84, $04, $84, $04, $84, $04, $84
	.byte $08, $88, $08, $88, $08, $88, $08, $88, $0c, $8c, $0c, $8c, $0c, $8c, $0c, $8c
	.byte $10, $90, $10, $90, $10, $90, $10, $90, $14, $94, $14, $94, $14, $94, $14, $94
	.byte $18, $98, $18, $98, $18, $98, $18, $98, $1c, $9c, $1c, $9c, $1c, $9c, $1c, $9c
attributeTableConversionH:
	.byte $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23
	.byte $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23 
	.byte $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23 
	.byte $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23, $23
	.byte $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27 
	.byte $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27 
	.byte $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27 
	.byte $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27
attributeTableConversionL:
	.byte $c0, $c8, $d0, $d8, $e0, $e8, $f0, $f8, $c1, $c9, $d1, $d9, $e1, $e9, $f1, $f9
	.byte $c2, $ca, $d2, $da, $e2, $ea, $f2, $fa, $c3, $cb, $d3, $db, $e3, $eb, $f3, $fb
	.byte $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc, $c5, $cd, $d5, $dd, $e5, $ed, $f5, $fd
	.byte $c6, $ce, $d6, $de, $e6, $ee, $f6, $fe, $c7, $cf, $d7, $df, $e7, $ef, $f7, $ff
	.byte $c0, $c8, $d0, $d8, $e0, $e8, $f0, $f8, $c1, $c9, $d1, $d9, $e1, $e9, $f1, $f9
	.byte $c2, $ca, $d2, $da, $e2, $ea, $f2, $fa, $c3, $cb, $d3, $db, $e3, $eb, $f3, $fb
	.byte $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc, $c5, $cd, $d5, $dd, $e5, $ed, $f5, $fd
	.byte $c6, $ce, $d6, $de, $e6, $ee, $f6, $fe, $c7, $cf, $d7, $df, $e7, $ef, $f7, $ff
