.include "lib.h"
.include "ppu.h"

.include "tiles.h"
.include "palettes.h"

PPUCTRL = $2000;(VPHB SINN) NMI enable (V), PPU master/slave (P), sprite height (H), background tile select (B), sprite tile select (S), increment mode (I), nametable select (NN)
PPUMASK = $2001;(BGRs bMmG)	color emphasis (BGR), sprite enable (s), background enable (b), sprite left column enable (M), background left column enable (m), greyscale (G)
PPUSTATUS = $2002;(VSO- ----) vblank (V), sprite 0 hit (S), sprite overflow (O); read resets write pair for $2005/$2006
PPUSCROLL = $2005;(xxxx xxxx) fine scroll position (two writes: X scroll, Y scroll)
PPUADDR = $2006;(aaaa aaaa)	PPU read/write address (two writes: most significant byte, least significant byte)
PPUDATA = $2007;(dddd dddd)	PPU data read/write

;Project ppu settings

BASE_NAMETABLE = 0;this here for ease of change
VRAM_INCREMENT = 1;0: add 1, going across; 1: add 32, going down
SPRITE_TABLE = 0;0: $0000, 1: $1000, ignored in 8x16 mode
BACKGROUND_TABLE = 1;0: $0000 1: $1000
SPRITE_SIZE = 1;0: 8x8 pixels 1: 8x16 pixels
PPU_MASTER_SLAVE = 0;unimplemented, leave this alone
GENERATE_NMI = 1; leave default as on

PPU_SETTINGS = BASE_NAMETABLE | (VRAM_INCREMENT << 2) | (SPRITE_TABLE << 3) | (BACKGROUND_TABLE << 4) | (SPRITE_SIZE << 5) |(PPU_MASTER_SLAVE << 6) | (GENERATE_NMI << 7)

;PPU_SETTINGS options
DISABLE_NMI = %01111111;AND 
INCREMENT_1 = %11111011;AND 
INCREMENT_32 = %00000100;OR
NAMETABLE_0 = %11111100;and
NAMETABLE_1 = %00000001;OR 
NAMETABLE_2 = %00000010;OR
NAMETABLE_3 = %00000011;OR

;project settings for mask
GREYSCALE = 0;0: normal color, 1: produce a greyscale display
LEFT_BACKGROUND = 0;1: Show background in leftmost 8 pixels of screen, 0: Hide
LEFT_SPRITES = 0;1: Show sprites in leftmost 8 pixels of screen, 0: Hide
SHOW_BACKGROUND = 0;1: shows backgrounds, 0: disables backgrounds
SHOW_SPRITES = 0;1: shows sprites, 0: disables sprites
RED_EMPHASIS = 0;1 is on 0 is off
GREEN_EMPHASIS = 0;1 is on 0 is off
BLUE_EMPHASIS = 0;1 is on 0 is off

MASK_SETTINGS = GREYSCALE | (LEFT_BACKGROUND << 1) | (LEFT_SPRITES << 2) | (SHOW_BACKGROUND <<3) | (SHOW_SPRITES << 4) | (RED_EMPHASIS << 5) | (GREEN_EMPHASIS << 6) | (BLUE_EMPHASIS << 7)

;MASK_SETTINGS options			Operation	
STANDARD_COLOR = %00011110		; and
EMPHASIZE_RED = %00100000		; or
EMPHASIZE_GREEN = %01000000		; or
EMPHASIZE_BLUE = %10000000		; or
ENABLE_RENDERING = %00011000	; or
DISABLE_RENDERING = %11100111	; and
DIM_SCREEN = %11100000			; or

.zeropage
currentNameTable: .res 2
currentPPUSettings: .res 1
currentMaskSettings: .res 1
tile16a: .res 1
tile16b: .res 1
tile16c: .res 1
tile16d: .res 1
frame_H: .res 1
frame_L: .res 1
xScroll: .res 1
yScroll_H: .res 1
yScroll_L: .res 1
scrollSpeed_H: .res 1
scrollSpeed_L: .res 1

.code

PPU_init:
	bit PPUSTATUS ;discharge capacitance
@vblankwait2:
	bit PPUSTATUS ;wait for vblank bit to be set
    bpl @vblankwait2
	;enable vertical blanking irq
	lda #PPU_SETTINGS
	;save ppu settings
	sta PPUCTRL
	sta currentPPUSettings
	;initialize mask settings
	lda #MASK_SETTINGS
	sta currentMaskSettings
	rts

disableRendering:;(void)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
	lda frame_L
@waitForBlank:
	cmp frame_L
	beq @waitForBlank
	lda currentMaskSettings
	and #DISABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

enableRendering:;(void)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
	lda frame_L
@waitForBlank:
	cmp frame_L
	beq @waitForBlank
	lda currentMaskSettings
	ora #ENABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

PPU_resetClock:
	lda #0
	sta frame_L
	sta frame_H

PPU_advanceClock:
	inc frame_L
	beq @overflow
	rts
@overflow:
	inc frame_H
	rts

renderAllPalettes:
	;clear vblank flag before write
	bit PPUSTATUS
	lda currentPPUSettings
	and #INCREMENT_1
	sta PPUCTRL
;palettes are at 3f00 of ppu, accessed through PPUADDR
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
@storePalettes:
;store in PPUDATA
	lda #BACKGROUND_COLOR
	sta PPUDATA
	lda color1,x
	sta PPUDATA
	lda color2,x
	sta PPUDATA
	lda color3,x
	sta PPUDATA
	inx
	cpx #$08;8 palettes
	bne @storePalettes
	rts

render32:;(a)
;this renders a 32x32 tile from the tiles32 array.
;arguments
;a - tile in tiles32 array to render
;returns void;
;a is tile position in tiles32
	tax;x is tile number in array
	tay;y is nametable reference pos
	;all tiles ending in 111 are shorter
	pha
	and #%00000111
	cmp #%00000111
	bne @standardTile
@shorterTile:
	;save the 2 tiles
	lda tiles32,x
	tax;x is now the 32x32 tile
	lda topLeft32,x
	sta tile16a
	lda topRight32,x
	sta tile16c
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversionH,y
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,y
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldx tile16a
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldx tile16c
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	jmp @attributeByte

@standardTile:
	;save the 4 tiles
	lda tiles32,x
	tax;x is now the 32x32 tile
	lda topLeft32,x
	sta tile16a
	lda bottomLeft32,x
	sta tile16b
	lda topRight32,x
	sta tile16c
	lda bottomRight32,x
	sta tile16d
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversionH,y
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,y
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldx tile16a
	ldy tile16b
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldx tile16c
	ldy tile16d
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
@attributeByte:
;get the tile
	pla
	tay;y is tile pos in tiles32 array
	tax;x is position in conversion
	lda attributeTableConversionH,x
	;store address (big endian)
	sta PPUADDR
	lda attributeTableConversionL,x
	sta PPUADDR
	lda tiles32,y
	tay;y is tile itself
	lda tileAttributeByte,y
	sta PPUDATA
	rts

renderAllTiles:
	;clear vblank bit before write
	bit PPUSTATUS
	lda currentPPUSettings
	ora #INCREMENT_32
	sta PPUCTRL
	ldx #$00
@renderScreenLoop:
	txa
	pha
	jsr render32
	pla
	tax
	inx
	cpx #64
	bcc	@renderScreenLoop
	rts
	
PPU_resetScroll:
	lda #1
	sta scrollSpeed_H
	lda #0
	sta scrollSpeed_L
	sta xScroll
	sta yScroll_H
	sta yScroll_L
	rts

PPU_updateScroll:
	sec
	lda yScroll_L
	sbc scrollSpeed_L
	sta yScroll_L
	lda yScroll_H
	sbc scrollSpeed_H
	cmp #240
	bcc @storeY
		eor #%11111111
		adc #0
		sta mathTemp
		sec
		lda #240
		sbc mathTemp
@storeY:
	sta yScroll_H
	rts

PPU_setScroll:
;discharge capacitance
	bit PPUSTATUS
	lda currentPPUSettings
	sta PPUCTRL
	lda xScroll
	sta PPUSCROLL
	lda yScroll_H
	sta PPUSCROLL
	rts

.rodata
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
