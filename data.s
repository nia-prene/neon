.segment "RAWDATA"

;;;;;;;;;;;;;;;;
;;;Scenes;;; 
;;;;;;;;;;;;;;;;
screenTile:
	.byte BEACH_SCREEN
paletteCollection:
	.byte BEACH_PALETTE
levelWave:
	.byte BEACH_WAVES
;;;;;;;;;;;
;;;tiles;;;
;;;;;;;;;;;
;screens;
;256x256;
;;;;;;;;;
BEACH_SCREEN=0
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
BULLET_SPRITE_0=3
spriteTile0:
	.byte $00, $60, $20, $24
spriteAttribute0:
	.byte %00000000, %00000010, %00000000, %00000000
spriteTile1:
	.byte $02, $60
spriteAttribute1:
	.byte %00000000, %01000010
spriteTile2:
	.byte $04, $60
spriteAttribute2:
	.byte %00000000, %00000010
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
romEnemyMetasprite:
	.byte NULL, TARGET_SPRITE, TARGET_SPRITE
romEnemyHP:
	.byte NULL, 10, 10
;the type determines the width, height, and how it is built in oam
romEnemyType: 
	.byte NULL, 01, 01
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

;;;;;;;;;;;;;
;enemy waves;
;;;;;;;;;;;;;
BEACH_WAVES=0
levelWavesH:
	.byte >beachWaves
levelWavesL:
	.byte <beachWaves
;waves for each level as index to pointers
beachWaves:
	.byte 0, 1, 0, 1
;pointers to individual enemy waves (below)
wavePointerH:
	.byte >wave0, >wave1
wavePointerL:
	.byte <wave0, <wave1
;individual enemy waves
wave0:
	.byte 1, 12, $ff
wave1:
	.byte 1, 15, 1, 05, 1, 25, $ff
;wave starting coordinates
waveX:
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
waveY:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;;;;;;;;;;;;;
;;;Bullets;;;
;;;;;;;;;;;;;
romEnemyBulletBehaviorH:
	.byte >bullet0, >bullet1, >bullet2, >bullet3, >bullet4, >bullet5, >bullet6, >bullet7, >bullet8, >bullet9, >bulletA, >bulletB, >bulletC, >bulletD, >bulletE, >bulletF
	.byte >bullet10, >bullet11, >bullet12, >bullet13, >bullet14, >bullet15, >bullet16, >bullet17, >bullet18, >bullet19, >bullet1A, >bullet1B, >bullet1C, >bullet1D, >bullet1E, >bullet1F
	.byte >bullet20, >bullet21, >bullet22, >bullet23, >bullet24, >bullet25, >bullet26, >bullet27, >bullet28, >bullet29, >bullet2A, >bullet2B, >bullet2C, >bullet2D, >bullet2E, >bullet2F
	.byte >bullet30, >bullet31, >bullet32, >bullet33, >bullet34, >bullet35, >bullet36, >bullet37, >bullet38, >bullet39, >bullet3A, >bullet3B, >bullet3C, >bullet3D, >bullet3E, >bullet3F
	.byte >bullet40, >bullet41, >bullet42, >bullet43, >bullet44, >bullet45, >bullet46, >bullet47, >bullet48, >bullet49, >bullet4A, >bullet4B, >bullet4C, >bullet4D, >bullet4E, >bullet4F
	.byte >bullet50, >bullet51, >bullet52, >bullet53, >bullet54, >bullet55, >bullet56, >bullet57, >bullet58, >bullet59, >bullet5A, >bullet5B, >bullet5C, >bullet5D, >bullet5E, >bullet5F
	.byte >bullet60, >bullet61, >bullet62, >bullet63, >bullet64, >bullet65, >bullet66, >bullet67, >bullet68, >bullet69, >bullet6A, >bullet6B, >bullet6C, >bullet6D, >bullet6E, >bullet6F
	.byte >bullet70, >bullet71, >bullet72, >bullet73, >bullet74, >bullet75, >bullet76, >bullet77, >bullet78, >bullet79, >bullet7A, >bullet7B, >bullet7C, >bullet7D, >bullet7E, >bullet7F
romEnemyBulletBehaviorL:
	.byte <bullet0-1, <bullet1-1, <bullet2-1, <bullet3-1, <bullet4-1, <bullet5-1, <bullet6-1, <bullet7-1, <bullet8-1, <bullet9-1, <bulletA-1, <bulletB-1, <bulletC-1, <bulletD-1, <bulletE-1, <bulletF-1
	.byte <bullet10-1, <bullet11-1, <bullet12-1, <bullet13-1, <bullet14-1, <bullet15-1, <bullet16-1, <bullet17-1, <bullet18-1, <bullet19-1, <bullet1A-1, <bullet1B-1, <bullet1C-1, <bullet1D-1, <bullet1E-1, <bullet1F-1
	.byte <bullet20-1, <bullet21-1, <bullet22-1, <bullet23-1, <bullet24-1, <bullet25-1, <bullet26-1, <bullet27-1, <bullet28-1, <bullet29-1, <bullet2A-1, <bullet2B-1, <bullet2C-1, <bullet2D-1, <bullet2E-1, <bullet2F-1
	.byte <bullet30-1, <bullet31-1, <bullet32-1, <bullet33-1, <bullet34-1, <bullet35-1, <bullet36-1, <bullet37-1, <bullet38-1, <bullet39-1, <bullet3A-1, <bullet3B-1, <bullet3C-1, <bullet3D-1, <bullet3E-1, <bullet3F-1
	.byte <bullet40-1, <bullet41-1, <bullet42-1, <bullet43-1, <bullet44-1, <bullet45-1, <bullet46-1, <bullet47-1, <bullet48-1, <bullet49-1, <bullet4A-1, <bullet4B-1, <bullet4C-1, <bullet4D-1, <bullet4E-1, <bullet4F-1
	.byte <bullet50-1, <bullet51-1, <bullet52-1, <bullet53-1, <bullet54-1, <bullet55-1, <bullet56-1, <bullet57-1, <bullet58-1, <bullet59-1, <bullet5A-1, <bullet5B-1, <bullet5C-1, <bullet5D-1, <bullet5E-1, <bullet5F-1
	.byte <bullet60-1, <bullet61-1, <bullet62-1, <bullet63-1, <bullet64-1, <bullet65-1, <bullet66-1, <bullet67-1, <bullet68-1, <bullet69-1, <bullet6A-1, <bullet6B-1, <bullet6C-1, <bullet6D-1, <bullet6E-1, <bullet6F-1
	.byte <bullet70-1, <bullet71-1, <bullet72-1, <bullet73-1, <bullet74-1, <bullet75-1, <bullet76-1, <bullet77-1, <bullet78-1, <bullet79-1, <bullet7A-1, <bullet7B-1, <bullet7C-1, <bullet7D-1, <bullet7E-1, <bullet7F-1
	
romEnemyBulletType:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
;type determines all future attributes, so sprites and hitboxes can be reused
romEnemyBulletWidth:
	.byte 8
romEnemyBulletHitboxY1:
	.byte 6
romEnemyBulletHitboxY2:
	.byte 5
romEnemyBulletHitboxX1:
	.byte 2
romEnemyBulletHitboxX2:
	.byte 04
romEnemyBulletMetasprite:
	.byte BULLET_SPRITE_0
;;;;;;;;;;;;;;;;
;;;animations;;;
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;;;color cycles;;;
;;;;;;;;;;;;;;;;;;
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

