.segment "RAWDATA"
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
CAT_PALETTE = 0
OASIS0 = 1
OASIS1 = 2
OASIS2 = 3
OASIS3 = 4
romColor1:
	.byte $23, $16, $05, $26, $07
romColor2:
	.byte $10, $26, $06, $34, $0b
romColor3:
	.byte $08, $31, $07, $2c, $1b

;;;;;;;;;;;;;
;;;sprites;;;
;;;;;;;;;;;;;;;;
;sprite objects;
;;;;;;;;;;;;;;;;
CAT_OBJECT = 0
inputMethod:
	.byte CONTROLLER_1
behavior:
	.byte PLAYER_BEHAVIOR
;metatile collections as states
spriteWidth:
	.byte 01
spriteHeight:
	.byte 01
spriteTotal:
	.byte 01
hitboxX1:
	.byte 02
hitboxX2:
	.byte 06
hitboxY1:
	.byte 02
hitboxY2:
	.byte 06
spriteState0:
	.byte CAT_IDLE_0
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
CAT_IDLE_0= 0
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
	.byte %00000000
spriteTile2:
	.byte $01
spriteAttribute2:
	.byte %00000000
spriteTile3:
	.byte $01 
spriteAttribute3:
	.byte %00000000
spriteTile4:
	.byte $01
spriteAttribute4:
	.byte %00000000
spriteTile5:
	.byte $01
spriteAttribute5:
	.byte %00000000
spriteTile6:
	.byte $01
spriteAttribute6:
	.byte %00000000
spriteTile7:
	.byte $01
spriteAttribute7:
	.byte %00000000
spriteTile8:
	.byte $01
spriteAttribute8:
	.byte %00000000
spriteTile9:
	.byte $01
spriteAttribute9:
	.byte %00000000
spriteTile10:
	.byte $01
spriteAttribute10:
	.byte %00000000
spriteTile11:
	.byte $01
spriteAttribute11:
	.byte %00000000
spriteTile12:
	.byte $01
spriteAttribute12:
	.byte %00000000
spriteTile13:
	.byte $01
spriteAttribute13:
	.byte %00000000
spriteTile14:
	.byte $01
spriteAttribute14:
	.byte %00000000
spriteTile15:
	.byte $01
spriteAttribute15:
	.byte %00000000
spriteTile16:
	.byte $01
spriteAttribute16:
	.byte %00000000
spriteTile17:
	.byte $01
spriteAttribute17:
	.byte %00000000
spriteTile18:
	.byte $01
spriteAttribute18:
	.byte %00000000
spriteTile19:
	.byte $01
spriteAttribute19:
	.byte %00000000
spriteTile20:
	.byte $01
spriteAttribute20:
	.byte %00000000
spriteTile21:
	.byte $01
spriteAttribute21:
	.byte %00000000
spriteTile22:
	.byte $01
spriteAttribute22:
	.byte %00000000
spriteTile23:
	.byte $01
spriteAttribute23:
	.byte %00000000
spriteTile24:
	.byte $01
spriteAttribute24:
	.byte %00000000
;;;;;;;;;;;;;;;
;sprite inputs;
;;;;;;;;;;;;;;;
CONTROLLER_1 = 0
CONTROLLER_2 = 1
;behaviors;
;;;;;;;;;;;
PLAYER_BEHAVIOR=0
behaviorsH:
	.byte >playerBehavior
behaviorsL:
	.byte <playerBehavior-1, $ff

playerBehavior:
	ldx objectToUpdate
	lda inputs,x
	clc
	lsr
	bcc @noRight
	inc spriteX,x
@noRight:
	lsr
	bcc @noLeft
	dec spriteX,x
@noLeft:
	lsr
	bcc @noDown
	inc spriteY,x
@noDown:
	lsr
	bcc @noUp
	dec spriteY,x
@noUp:
	rts

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
