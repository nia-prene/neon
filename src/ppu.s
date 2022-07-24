.include "lib.h"
.include "ppu.h"

.include "tiles.h"
.include "score.h"
.include "main.h"
.include "hud.h"
.include "palettes.h"
.include "player.h"
.include "oam.h"
.include "textbox.h"

PPUCTRL = $2000;(VPHB SINN) NMI enable (V), PPU master/slave (P), sprite height (H), background tile select (B), sprite tile select (S), increment mode (I), nametable select (NN)
PPUMASK = $2001;(BGRs bMmG)	color emphasis (BGR), sprite enable (s), background enable (b), sprite left column enable (M), background left column enable (m), greyscale (G)
PPUSTATUS = $2002;(VSO- ----) vblank (V), sprite 0 hit (S), sprite overflow (O); read resets write pair for $2005/$2006
PPUSCROLL = $2005;(xxxx xxxx) fine scroll position (two writes: X scroll, Y scroll)
PPUADDR = $2006;(aaaa aaaa)	PPU read/write address (two writes: most significant byte, least significant byte)
PPUDATA = $2007;(dddd dddd)	PPU data read/write

;Project ppu settings

BASE_NAMETABLE = 0;this here for ease of change
VRAM_INCREMENT = 0;0: add 1, going across; 1: add 32, going down
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
LEFT_BACKGROUND = 1;1: Show background in leftmost 8 pixels of screen, 0: Hide
LEFT_SPRITES = 1;1: Show sprites in leftmost 8 pixels of screen, 0: Hide
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
DISABLE_SPRITES= %11101111		; and
DIM_SCREEN = %11100000			; or
LIGHTEN_SCREEN = %00011111		; and
.macro sws oldStack, newStack
	tsx
	stx oldStack
	ldx newStack
	txs
.endmacro
.zeropage
PPU_willVRAMUpdate:.res 1
currentNameTable: .res 2
currentPPUSettings: .res 1
currentMaskSettings: .res 1
tile16a: .res 1
tile16b: .res 1
tile16c: .res 1
tile16d: .res 1
xScroll: .res 1
yScroll_H: .res 1
yScroll_L: .res 1
scrollSpeed_H: .res 1
scrollSpeed_L: .res 1
tile128a: .res 1
tile128b: .res 1
tile64a: .res 1
tile64b: .res 1
tile64c: .res 1
tile64d: .res 1
PPU_stack: .res 1
PPU_bufferBytes:.res 1

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
	lda Main_frame_L
@waitForBlank:
	cmp Main_frame_L
	beq @waitForBlank
	lda currentMaskSettings
	and #DISABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

enableRendering:;(a)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
	lda Main_frame_L
@waitForBlank:
	cmp Main_frame_L
	beq @waitForBlank
	lda currentMaskSettings
	ora #ENABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

PPU_renderRightScreen:
	lda currentPPUSettings
	and #INCREMENT_1
	sta PPUCTRL
	lda #$24
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #192
	lda #$02
@HUDLoop:
	sta PPUDATA
	dex
	bne @HUDLoop
	ldx #7-1
@textbox:
	ldy #8-1
	lda #$2
@left:
	sta PPUDATA
	dey
	bpl @left
	lda #$4
	ldy #21-1
@center:
	sta PPUDATA
	dey
	bpl @center
	ldy #3-1
	lda #$2
@right:
	sta PPUDATA
	dey
	bpl @right
	dex
	bpl @textbox
	ldx #31
@bottom:
	sta PPUDATA
	dex
	bpl @bottom
;render attribute bytes
	lda #$27
	sta PPUADDR
	lda #$C0
	sta PPUADDR
	ldx #64-1
	lda #%11111111
@attributeLoop:
	sta PPUDATA
	dex
	bpl @attributeLoop
	rts

PPU_waitForSprite0Reset:;void()
;waits for sprite 0 hit to turn off at beginnign of frame
	lda #%01000000
@waitForReset:
	bit PPUSTATUS
	bne @waitForReset
	rts

PPU_waitForSprite0Hit:
	lda currentMaskSettings
	and #DISABLE_SPRITES
	pha ;Mask to disable sprites

	lda Sprite0_destination
	and #$f8
	asl
	asl
	pha;Low byte nametable address ((Y & $F8) << 2)|(X >> 3)

	lda #0
	pha;X to $2005

	lda Sprite0_destination
	pha;- Y to $2005

	lda #4
	pha ;Nametable << 2 (that is: $00, $04, $08, or $0C) to $2006
	
	lda #%01000000
	bit PPUSTATUS
	beq @waitForHit
		pla ;nametable hi
		pla ;Y
		pla ;X
		pla ;nametabel lo 
		pla ;Mask
		rts

@waitForHit:
	bit PPUSTATUS
	beq @waitForHit
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pla
	sta $2006
	pla 
	sta $2005
	pla 
	sta $2005
	pla
	sta $2006
	pla
	sta PPUMASK
	rts

PPU_dimScreen:;void()
	lda currentMaskSettings
	ora #DIM_SCREEN
	sta PPUMASK
	sta currentMaskSettings
	rts

PPU_lightenScreen:;void()
	lda currentMaskSettings
	and #LIGHTEN_SCREEN
	sta PPUMASK
	sta currentMaskSettings
	rts

PPU_NMIPlan00:
;byte writes INCLUDE functions pushed on stack
MAX_BYTES=70
SCORE_BYTES=24
HEART_BYTES=7
PALETTE_BYTES=5
;save the main stack
	tsx
	stx Main_stack
;make a new ppu stack, large enough to hold all byte writes and a couple addresses if interrupted
	ldx #MAX_BYTES+8
	txs
;after routine runs, return at the end of NMI
	lda #>(Main_NMIReturn-1)
	pha
	lda #<(Main_NMIReturn-1)
	pha
	tsx
	stx PPU_stack
	ldx Main_stack
	txs
;we just stored 2 bytes
	lda #2
	sta PPU_bufferBytes
;check if score needs updating
	lda Score_hasChanged
	beq :+
		clc
		lda #SCORE_BYTES
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_scoreToBuffer
	;update has been made
		lda #FALSE
		sta Score_hasChanged
:	
	lda Player_haveHeartsChanged
	beq :+
		clc
		lda #HEART_BYTES
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_heartsToBuffer
	;update has been made
		lda #FALSE
		sta Player_haveHeartsChanged
:
	ldy #NUMBER_OF_PALETTES-1
@paletteLoop:
	lda Palettes_hasChanged,y
	beq :+
	;check that byte buffer isnt overflowing
		clc
		lda #PALETTE_BYTES
		adc PPU_bufferBytes
		cmp #MAX_BYTES
		bcs @bufferFull
		;update the palette
			sta PPU_bufferBytes
			jsr PPU_paletteToBuffer
			lda #FALSE
			sta Palettes_hasChanged,y
:	dey
	bpl @paletteLoop
@bufferFull:
	lda #TRUE
	sta PPU_willVRAMUpdate
	rts

PPU_NMIPlan01:
;fades in colors
;save the main stack
	tsx
	stx Main_stack
;make a new ppu stack, large enough to hold all byte writes and a couple addresses if interrupted
	ldx #MAX_BYTES+8
	txs
;after routine runs, return at the end of NMI
	lda #>(Main_NMIReturn-1)
	pha
	lda #<(Main_NMIReturn-1)
	pha
	ldx #7
@loop:
	sec
	lda color3,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda color2,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda color1,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda backgroundColor
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	dex
	bpl @loop
	lda #$00
	pha
	lda #$3f
	pha
	lda #>(PPU_renderAllPalettesNMI-1)
	pha
	lda #<(PPU_renderAllPalettesNMI-1)
	pha
	sws PPU_stack, Main_stack
;do this during nmi
	lda #TRUE
	sta PPU_willVRAMUpdate
	rts
@colorMutator:
	.byte $30, $20, $10, $00

PPU_NMIPlan02:
;byte writes INCLUDE functions pushed on stack
PORTRAIT_BYTES=18
;save the main stack
	tsx
	stx Main_stack
;make a new ppu stack, large enough to hold all byte writes and a couple addresses if interrupted
	ldx #MAX_BYTES+8
	txs
;after routine runs, return at the end of NMI
	lda #>(Main_NMIReturn-1)
	pha
	lda #<(Main_NMIReturn-1)
	pha
	sws PPU_stack, Main_stack
;we just stored 2 bytes
	lda #2
	sta PPU_bufferBytes
;check if portrait needs updating
	lda Portraits_hasChanged
	beq :+
		clc
		lda #PORTRAIT_BYTES
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_portraitToBuffer
	;update has been made
		lda #FALSE
		sta Portraits_hasChanged
:	
	ldy #3
	lda Palettes_hasChanged,y
	beq :+
		jsr PPU_paletteToBuffer
		lda #FALSE
		sta Palettes_hasChanged,y
:
@bufferFull:
	lda #TRUE
	sta PPU_willVRAMUpdate
	rts

PPU_NMIPlan03:
;fades out colors
;save the main stack
	tsx
	stx Main_stack
;make a new ppu stack, large enough to hold all byte writes and a couple addresses if interrupted
	ldx #MAX_BYTES+8
	txs
;after routine runs, return at the end of NMI
	lda #>(Main_NMIReturn-1)
	pha
	lda #<(Main_NMIReturn-1)
	pha
	ldx #7
@loop:
	sec
	lda color3,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda color2,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda color1,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	lda backgroundColor
	sbc @colorMutator,y
	bcs :+
		lda #$0f
:
	pha
	dex
	bpl @loop
	lda #$00
	pha
	lda #$3f
	pha
	lda #>(PPU_renderAllPalettesNMI-1)
	pha
	lda #<(PPU_renderAllPalettesNMI-1)
	pha
	sws PPU_stack, Main_stack
;do this during nmi
	lda #TRUE
	sta PPU_willVRAMUpdate
	rts
@colorMutator:
	.byte $00, $10, $20, $30


PPU_renderAllPalettesNMI:
	pla
	sta PPUADDR
	pla
	sta PPUADDR
;palette0
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette1
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette2
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette3
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette4
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette5
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette6
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
;palette7
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts 

PPU_renderScoreNMI:
	pla
	sta PPUADDR
	pla
	sta PPUADDR
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUADDR
	pla
	sta PPUADDR
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts

render32:;(a)
;this renders a 32x32 tile from the tiles32 array.
;arguments
;a - tile in tiles32 array to render
;returns void;
;a is tile position in tiles32
	tay;y is tile number in array
	tax;x is nametable reference pos
	;all tiles ending in 111 are shorter
	pha
	and #%00000111
	cmp #%00000111
	bne @standardTile
@shorterTile:
	;save the 2 tiles
	lda (Tiles_screenPointer),y
	tay;y is now the 32x32 tile
	lda topLeft32,y
	sta tile16a
	lda topRight32,y
	sta tile16c
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversionH,x
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,x
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldy tile16a
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldy tile16c
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	jmp @attributeByte

@standardTile:
	;save the 4 tiles
	lda (Tiles_screenPointer),y
	tay;y is now the 32x32 tile
	lda topLeft32,y
	sta tile16a
	lda bottomLeft32,y
	sta tile16b
	lda topRight32,y
	sta tile16c
	lda bottomRight32,y
	sta tile16d
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversionH,x
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,x
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldy tile16a
	ldx tile16b
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldy tile16c
	ldx tile16d
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
@attributeByte:
;get the tile
	pla
	tay;y is tile pos in tiles32 array
	tax;x is position in conversion
	lda #$23
	;store address (big endian)
	sta PPUADDR
	lda attributeTableConversionL,x
	sta PPUADDR
	lda (Tiles_screenPointer),y
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
	lda #3
	sta scrollSpeed_H
	lda #128
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
	lda currentMaskSettings
	sta PPUMASK
	lda #0
	sta PPUSCROLL
	lda yScroll_H
	sta PPUSCROLL
	lda currentPPUSettings
	sta PPUCTRL
	rts



.proc PPU_scoreToBuffer
SCORE_ADDRESS_TOP=$2436
SCORE_ADDRESS_BOTTOM=$2456
;arguments
;y - player
	ldy #0
;swap stacks
	sws Main_stack, PPU_stack
;start at the end (ones digit
	lda Score_ones,y
	tax
	lda @tileBottom,x
	pha

	lda Score_tens,y
	tax
	lda @tileBottom,x
	pha

	lda Score_hundreds,y
	tax
	lda @tileBottom,x
	pha
	
	lda #COMMA_BOTTOM
	pha
	
	lda Score_thousands,y
	tax
	lda @tileBottom,x
	pha
	
	lda Score_tenThousands,y
	tax
	lda @tileBottom,x
	pha
	
	lda Score_hundredThousands,y
	tax
	lda @tileBottom,x
	pha
;comma	
	lda #COMMA_BOTTOM
	pha

	lda Score_millions,y
	tax
	lda @tileBottom,x
	pha
	
	lda #<SCORE_ADDRESS_BOTTOM
	pha
	lda #>SCORE_ADDRESS_BOTTOM
	pha

;start at the end (ones digit
	lda Score_ones,y
	tax
	lda @tileTop,x
	pha

	lda Score_tens,y
	tax
	lda @tileTop,x
	pha

	lda Score_hundreds,y
	tax
	lda @tileTop,x
	pha
	
	lda #COMMA_TOP 
	pha
	
	lda Score_thousands,y
	tax
	lda @tileTop,x
	pha
	
	lda Score_tenThousands,y
	tax
	lda @tileTop,x
	pha
	
	lda Score_hundredThousands,y
	tax
	lda @tileTop,x
	pha
;comma	
	lda #COMMA_TOP 
	pha

	lda Score_millions,y
	tax
	lda @tileTop,x
	pha
	
	lda #<SCORE_ADDRESS_TOP
	pha
	lda #>SCORE_ADDRESS_TOP
	pha

;subroutine that handles nmi rendering
	lda #>(PPU_renderScoreNMI-1)
	pha
	lda #<(PPU_renderScoreNMI-1)
	pha
;swap back stacks
	sws PPU_stack, Main_stack
	rts
@tileTop:
	.byte ZERO_TOP, ONE_TOP, TWO_TOP, THREE_TOP, FOUR_TOP, FIVE_TOP, SIX_TOP, SEVEN_TOP, EIGHT_TOP, NINE_TOP
@tileBottom:
	.byte ZERO_BOTTOM, ONE_BOTTOM, TWO_BOTTOM, THREE_BOTTOM, FOUR_BOTTOM, FIVE_BOTTOM, SIX_BOTTOM, SEVEN_BOTTOM, EIGHT_BOTTOM, NINE_BOTTOM
ZERO_TOP=$ff
ZERO_BOTTOM=$f5
ONE_TOP=$f0
ONE_BOTTOM=$f1
TWO_TOP=$f2
TWO_BOTTOM=$f3
THREE_TOP=$f4
THREE_BOTTOM=$f5
FOUR_TOP=$f6
FOUR_BOTTOM=$f7
FIVE_TOP=$f8
FIVE_BOTTOM=$f5
SIX_TOP=$f9
SIX_BOTTOM=$f5
SEVEN_TOP=$fa
SEVEN_BOTTOM=$fb
EIGHT_TOP=$fc
EIGHT_BOTTOM=$f5
NINE_TOP=$fd
NINE_BOTTOM=$fe
COMMA_TOP = $02
COMMA_BOTTOM = $ED
.endproc

.proc PPU_heartsToBuffer
MAX_HEARTS=5
HEART_FULL_TILE=$ee	
HEART_EMPTY_TILE=$ef	
HEART_ADDRESS=$2421
	ldy #0;player zero
;swap stacks
	sws Main_stack, PPU_stack
;find how many hearts are empty
	sec
	lda #MAX_HEARTS
	sbc Player_hearts,y
	beq @heartsFull;skip if hearts are full
		tax
	@emptyTileLoop:
	;fill in top with empty tiles
		lda #HEART_EMPTY_TILE
		pha
		dex
		bne @emptyTileLoop
@heartsFull:
;find how many full hearts there are
	ldx Player_hearts,y
	beq @heartsEmpty
	@fullTileLoop:
	;fill in full hearts
		lda #HEART_FULL_TILE
		pha
		dex
		bne @fullTileLoop
@heartsEmpty:
;addresses
	lda #<HEART_ADDRESS
	pha
	lda #>HEART_ADDRESS
	pha
;NMI render function pointer
	lda #>(PPU_renderHeartsNMI-1)
	pha
	lda #<(PPU_renderHeartsNMI-1)
	pha
;swap out the stacks
	sws PPU_stack, Main_stack
	rts
.endproc

PPU_renderHeartsNMI:
	pla
	sta PPUADDR
	pla
	sta PPUADDR

	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts

PPU_paletteToBuffer:;void(y)
;arguments 
;y - palette to update
;swap stacks
	sws Main_stack, PPU_stack
;get the colors
	lda color3,y
	pha
	lda color2,y
	pha
	lda color1,y
	pha
;address
	lda @paletteAddress_L,y
	pha
	lda #$3f
	pha
;function address
	lda #>(PPU_renderPaletteNMI-1)
	pha
	lda #<(PPU_renderPaletteNMI-1)
	pha
	
;switch stack back
	sws PPU_stack, Main_stack 
	rts
@paletteAddress_L:
	.byte $01, $05, $09, $0d, $11, $15, $19, $1d

PPU_renderPaletteNMI:
;store address
	pla
	sta PPUADDR
	pla
	sta PPUADDR
;store colors
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts

PPU_portraitToBuffer:
	sws Main_stack, PPU_stack
;set up pointer
	ldy Portraits_current
	lda Portraits_L,y
	sta Portraits_pointer
	lda Portraits_H,y
	sta Portraits_pointer+1
	ldy #16-1;16 tiles
@loop:
	lda (Portraits_pointer),y
	pha
	dey
	bpl @loop
	lda #>(PPU_renderPortraitNMI-1)
	pha
	lda #<(PPU_renderPortraitNMI-1)
	pha
	sws PPU_stack, Main_stack
	rts

PPU_renderPortraitNMI:
PORTRAIT_ADDRESS=$24c3
	lda #>PORTRAIT_ADDRESS
	sta PPUADDR
	lda #<PORTRAIT_ADDRESS
	sta PPUADDR

	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA

	lda #>(PORTRAIT_ADDRESS+$20)
	sta PPUADDR
	lda #<(PORTRAIT_ADDRESS+$20)
	sta PPUADDR
	
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA

	lda #>(PORTRAIT_ADDRESS+$40)
	sta PPUADDR
	lda #<(PORTRAIT_ADDRESS+$40)
	sta PPUADDR

	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA

	lda #>(PORTRAIT_ADDRESS+$60)
	sta PPUADDR
	lda #<(PORTRAIT_ADDRESS+$60)
	sta PPUADDR

	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts

.rodata
nameTableConversionH:
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
	.byte $20, $20, $21, $21, $22, $22, $23, $23, $20, $20, $21, $21, $22, $22, $23, $23
nameTableConversionL:
	.byte $00, $80, $00, $80, $00, $80, $00, $80, $04, $84, $04, $84, $04, $84, $04, $84 
	.byte $08, $88, $08, $88, $08, $88, $08, $88, $0c, $8c, $0c, $8c, $0c, $8c, $0c, $8c 
	.byte $10, $90, $10, $90, $10, $90, $10, $90, $14, $94, $14, $94, $14, $94, $14, $94 
	.byte $18, $98, $18, $98, $18, $98, $18, $98, $1c, $9c, $1c, $9c, $1c, $9c, $1c, $9c
attributeTableConversionL:
	.byte $c0, $c8, $d0, $d8, $e0, $e8, $f0, $f8, $c1, $c9, $d1, $d9, $e1, $e9, $f1, $f9
	.byte $c2, $ca, $d2, $da, $e2, $ea, $f2, $fa, $c3, $cb, $d3, $db, $e3, $eb, $f3, $fb
	.byte $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc, $c5, $cd, $d5, $dd, $e5, $ed, $f5, $fd
	.byte $c6, $ce, $d6, $de, $e6, $ee, $f6, $fe, $c7, $cf, $d7, $df, $e7, $ef, $f7, $ff
