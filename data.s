.segment "RAWDATA"

;;;;;;;;;;;;;;;;
;;;Scenes;;; 
;;;;;;;;;;;;;;;;
screenTile:
	.byte $0
paletteCollection:
	.byte BEACH_PALETTE

;;;;;;;;;;;
;;;tiles;;;
;;;;;;;;;;;
;screens;
;256x256;
;;;;;;;;;
topLeft256:
	.byte $00
bottomLeft256:
	.byte $01
topRight256:
	.byte $02
bottomRight256:
	.byte $03
;;;;;;;;;
;128x128;
;;;;;;;;;
topLeft128:
	.byte $00, $01, $05, $07
bottomLeft128:
	.byte $00, $02, $06, $08
topRight128:
	.byte $03, $03, $09, $0b
bottomRight128:
	.byte $03, $04, $0a, $0c
;;;;;;;
;64x64;
;;;;;;;
topLeft64:
	.byte $00, $00, $04, $08, $09, $0b, $0b, $0b, $0b, $0d, $0d, $11, $11
bottomLeft64:
	.byte $00, $02, $06, $08, $0a, $0b, $0b, $0b, $0b, $0d, $0f, $11, $13
topRight64:
	.byte $01, $01, $05, $0b, $0b, $0c, $0c, $10, $10, $14, $14, $14, $14
bottomRight64:
	.byte $01, $03, $07, $0b, $0b, $0c, $0e, $10, $12, $14, $14, $14, $14
;;;;;;;
;32x32;
;;;;;;;
topLeft32:
	.byte $04, $04, $04, $04, $0a, $0a, $05, $05, $0c, $10, $0e, $03, $03, $13, $03, $17
	.byte $03, $1b, $03, $1d, $01
bottomLeft32:
	.byte $05, $05, $09, $09, $04, $04, $04, $04, $0e, $0c, $0c, $03, $03, $15, $03, $19
	.byte $03, $19, $03, $13, $01
topRight32:
	.byte $06, $08, $06, $08, $0b, $0b, $07, $07, $0d, $11, $0d, $03, $12, $01, $16, $01
	.byte $1a, $01, $1c, $01, $01
bottomRight32:
	.byte $07, $07, $07, $07, $06, $08, $06, $08, $0f, $0d, $0f, $03, $14, $01, $18, $01
	.byte $18, $01, $12, $01, $01
tileAttributeByte:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01010101, %01010101, %01010101, %01010101, %01010101, %10101010, %01010101, %10101010
	.byte %01010101, %10101010, %01010101, %10101010, %10101010
;;;;;;;
;16x16;
;;;;;;;
topLeft16:
	.byte $00, $01, $02, $03, $06, $09, $04, $03, $04, $09, $11, $13, $17, $19, $1d, $1f
	.byte $23, $25, $2a, $2d, $03, $32, $03, $37, $03, $30, $29, $35, $29, $35
bottomLeft16:
	.byte $00, $01, $02, $03, $03, $04, $06, $09, $06, $00, $04, $15, $1a, $1c, $20, $22
	.byte $26, $28, $03, $30, $29, $35, $2a, $2d, $03, $32, $2a, $2d, $03, $37
topRight16:
	.byte $00, $01, $02, $03, $07, $0a, $0b, $0d, $0f, $0a, $12, $14, $18, $03, $1e, $03
	.byte $24, $03, $2c, $2e, $2b, $33, $03, $38, $2f, $31, $34, $36, $34, $36
bottomRight16:
	.byte $00, $01, $02, $03, $08, $05, $0c, $0e, $07, $10, $0f, $16, $1b, $03, $21, $03
	.byte $27, $03, $2f, $31, $34, $36, $2c, $2e, $2b, $33, $2c, $2e, $03, $38
;;;;;;;;;;;;;;
;;;palettes;;;
;;;;;;;;;;;;;;
PLAYER_PALETTE= 0
BEACH_0= 1
BEACH_1= 2
BEACH_2= 3
TARGET_PALETTE=4
PURPLE_BULLET=5
romColor1:
	.byte $07, $17, $2b, $01, $1d, $04
romColor2:
	.byte $25, $19, $23, $21, $05, $24
romColor3:
	.byte $35, $29, $37, $31, $30, $34
;;;;;;;;;;;;;
;collections;
;;;;;;;;;;;;;
BEACH_PALETTE = 0
palette0:
	.byte BEACH_0
palette1:
	.byte BEACH_1
palette2:
	.byte BEACH_2
palette3:
	.byte BEACH_2

;;;;;;;;;;;;;
;;;sprites;;;
;;;;;;;;;;;;;
romHitboxY1:
	.byte 02, 03
romHitboxY2:
	.byte 06, 10

;;;;;;;;;;;;;
;metasprites;
;;;;;;;;;;;;;
;tileTotal, tileWidth, tiles, attributes
;76543210
;||||||||
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
PLAYER_SPRITE = 0
TARGET_SPRITE = 1
PLAYER_MAIN_BULLET = 2
spriteTile0:
	.byte $00, $60, $20
spriteAttribute0:
	.byte %00000000, %00000010, %00000000
spriteTile1:
	.byte $02, $60
spriteAttribute1:
	.byte %00000000, %01000010
spriteTile2:
	.byte $04, $60
spriteAttribute2:
	.byte %00000001, %00000010
spriteTile3:
	.byte $06, $60
spriteAttribute3:
	.byte %00000000, %01000010

;;;;;;;;;;;;;
;;;Enemies;;;
;;;;;;;;;;;;;
;behaviors found in main.s
;first byte is a burner byte so we can use zero flag to denote empty slot
romEnemyBehaviorH:
	.byte NULL, >targetBehavior
romEnemyBehaviorL:
	.byte NULL, <targetBehavior-1
;the type determines the width, height, and how it is built in oam
romEnemyType: 
	.byte NULL, 01 
romEnemyWidth:
	.byte 8, 16, 16, 32
romEnemyHeight:
	.byte 16, 16, 32, 16
romEnemyHitboxX1:
	.byte 1, 2, 2, 2
romEnemyHitboxX2:
	.byte 6, 12, 12, 30
romEnemyHitboxY2:
	.byte 14, 14, 30, 14
enemySlot0:
	.byte $01
enemySlot1:
enemySlot2:
enemySlot3:
enemySlot4:
enemySlot5:
enemySlot6:
enemySlot7:
enemySlot8:
enemySlot9:
;;;;;;;;;;;;;;;;;;;;;;;
;enemy slot coordinate;
;;;;;;;;;;;;;;;;;;;;;;;
slotX:
	.byte 00
slotY:
	.byte 00
;;;;;;;;;;;;;;;;
;;;animations;;;
;;;;;;;;;;;;;;;;
playerIdleAnimation:
playerLeftAnimation:
playerRightAnimation:
;;;;;;;;;;;;;;;;;;
;;;color cycles;;;
;;;;;;;;;;;;;;;;;;
playerHitbox:
	.byte $05, $15, $25, $35, $30, $35, $25, $15 
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
.segment "RAWDATA"

