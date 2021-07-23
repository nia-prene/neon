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
	.byte %00000000, %00000010, %00000000, %00000011
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
romEnemyHPH:
	.byte NULL, 10, 10
romEnemyHPL:
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


;;;;;;;;;;;;;;;;
;;;animations;;;
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;;;color cycles;;;
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;lookup tables;;;
;;;;;;;;;;;;;;;;;;;


octant_adjust:
	.byte %11000000		;; x+,y-,|x|>|y|
	.byte %11111111		;; x+,y-,|x|<|y|
	.byte %00111111		;; x+,y+,|x|>|y|
	.byte %00000000		;; x+,y+,|x|<|y|
	.byte %10111111		;; x-,y-,|x|>|y|
	.byte %10000000		;; x-,y-,|x|<|y|
	.byte %01000000		;; x-,y+,|x|>|y|
	.byte %01111111		;; x-,y+,|x|<|y|

;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;
atan_tab:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $03,$03,$03,$03,$03,$03,$03,$03
	.byte $03,$03,$03,$03,$03,$04,$04,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $05,$05,$05,$05,$05,$05,$05,$05
	.byte $06,$06,$06,$06,$06,$06,$06,$06
	.byte $07,$07,$07,$07,$07,$07,$08,$08
	.byte $08,$08,$08,$08,$09,$09,$09,$09
	.byte $09,$0a,$0a,$0a,$0a,$0b,$0b,$0b
	.byte $0b,$0c,$0c,$0c,$0c,$0d,$0d,$0d
	.byte $0d,$0e,$0e,$0e,$0e,$0f,$0f,$0f
	.byte $10,$10,$10,$11,$11,$11,$12,$12
	.byte $12,$13,$13,$13,$14,$14,$15,$15
	.byte $15,$16,$16,$17,$17,$17,$18,$18
	.byte $19,$19,$19,$1a,$1a,$1b,$1b,$1c
	.byte $1c,$1c,$1d,$1d,$1e,$1e,$1f,$1f

;;;;;;;; log2(x)*32 ;;;;;;;;
log2_tab:	
	.byte $00,$00,$20,$32,$40,$4a,$52,$59
	.byte $60,$65,$6a,$6e,$72,$76,$79,$7d
	.byte $80,$82,$85,$87,$8a,$8c,$8e,$90
	.byte $92,$94,$96,$98,$99,$9b,$9d,$9e
	.byte $a0,$a1,$a2,$a4,$a5,$a6,$a7,$a9
	.byte $aa,$ab,$ac,$ad,$ae,$af,$b0,$b1
	.byte $b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9
	.byte $b9,$ba,$bb,$bc,$bd,$bd,$be,$bf
	.byte $c0,$c0,$c1,$c2,$c2,$c3,$c4,$c4
	.byte $c5,$c6,$c6,$c7,$c7,$c8,$c9,$c9
	.byte $ca,$ca,$cb,$cc,$cc,$cd,$cd,$ce
	.byte $ce,$cf,$cf,$d0,$d0,$d1,$d1,$d2
	.byte $d2,$d3,$d3,$d4,$d4,$d5,$d5,$d5
	.byte $d6,$d6,$d7,$d7,$d8,$d8,$d9,$d9
	.byte $d9,$da,$da,$db,$db,$db,$dc,$dc
	.byte $dd,$dd,$dd,$de,$de,$de,$df,$df
	.byte $df,$e0,$e0,$e1,$e1,$e1,$e2,$e2
	.byte $e2,$e3,$e3,$e3,$e4,$e4,$e4,$e5
	.byte $e5,$e5,$e6,$e6,$e6,$e7,$e7,$e7
	.byte $e7,$e8,$e8,$e8,$e9,$e9,$e9,$ea
	.byte $ea,$ea,$ea,$eb,$eb,$eb,$ec,$ec
	.byte $ec,$ec,$ed,$ed,$ed,$ed,$ee,$ee
	.byte $ee,$ee,$ef,$ef,$ef,$ef,$f0,$f0
	.byte $f0,$f1,$f1,$f1,$f1,$f1,$f2,$f2
	.byte $f2,$f2,$f3,$f3,$f3,$f3,$f4,$f4
	.byte $f4,$f4,$f5,$f5,$f5,$f5,$f5,$f6
	.byte $f6,$f6,$f6,$f7,$f7,$f7,$f7,$f7
	.byte $f8,$f8,$f8,$f8,$f9,$f9,$f9,$f9
	.byte $f9,$fa,$fa,$fa,$fa,$fa,$fb,$fb
	.byte $fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc
	.byte $fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
	.byte $fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff

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

