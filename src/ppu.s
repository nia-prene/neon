.include "lib.h"
.include "ppu.h"

.include "scenes.h"
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

Scroll_delta: .res 1
currentNameTable: .res 2
currentPPUSettings: .res 1
currentMaskSettings: .res 1
xScroll: .res 1
yScroll_H: .res 1
yScroll_L: .res 1
PPU_scrollSpeed_h: .res 1
PPU_scrollSpeed_l: .res 1
PPU_stack: .res 1
PPU_bufferBytes:.res 1

.data 
PPU_bufferReady:	.res 1

tile16a: .res 1
tile16b: .res 1
tile16c: .res 1
tile16d: .res 1
tile128a: .res 1
tile128b: .res 1
tile64a: .res 1
tile64b: .res 1
tile64c: .res 1
tile64d: .res 1


.code

PPU_init:

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
	lda currentMaskSettings
	and #DISABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts


enableRendering:;(a)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
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

	rts

PPU_lightenScreen:;void()
	lda currentMaskSettings
	and #LIGHTEN_SCREEN
	sta PPUMASK
	sta currentMaskSettings
	rts

PPU_NMIPlan00:
;byte writes INCLUDE functions pushed on stack
MAX_BYTES=128
PALETTE_BYTES=5
BYTES_BACKGROUND = 3;		color and address
	
	lda PPU_bufferReady;		if buffer is full from last frame
	beq :+
		rts
	:
	tsx;save the main stack
	stx Main_stack
;make a new ppu stack, large enough to hold all byte writes and a couple addresses if interrupted
	ldx #(MAX_BYTES + 8)
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
	
	lda Palettes_backgroundChanged
	beq @noBackground
		clc
		lda #BYTES_BACKGROUND
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_backgroundColorToBuffer
		lda #FALSE
		sta Palettes_backgroundChanged
@noBackground:	
	lda Score_hasChanged;check if score needs updating
	beq @noScore
		clc
		lda #BYTES_SCORE
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_scoreToBuffer
	;update has been made
		lda #FALSE
		sta Score_hasChanged
@noScore:	

	lda Player_haveHeartsChanged;check if hearts need update
	beq @noHearts
		clc
		lda #BYTES_HEARTS
		adc PPU_bufferBytes
		sta PPU_bufferBytes
		jsr PPU_heartsToBuffer
	;update has been made
		lda #FALSE
		sta Player_haveHeartsChanged
@noHearts:

	lda Player_haveBombsChanged
	beq @skipBombs
		clc
		lda #BYTES_BOMBS
		adc PPU_bufferBytes
		cmp #MAX_BYTES
		bcs @bufferFull
		sta PPU_bufferBytes
		jsr PPU_bombsToBuffer
	;update has been made
		lda #FALSE
		sta Player_haveBombsChanged
@skipBombs:
	
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
	sta PPU_bufferReady

@return:
	rts


PPU_NMIPlan01:; void(a) |
;fades in colors
;save the main stack

	lsr
	lsr
	lsr

	and #%11; msb of g
	tay
	
	lda PPU_bufferReady;		if buffer is full from last frame
	bne @return

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
		sec
:
	pha
	lda color2,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
		sec
:
	pha
	lda color1,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
		sec
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

	lda #TRUE
	sta PPU_bufferReady
@return:
	rts

@colorMutator:
	.byte $30, $20, $10, $00


PPU_NMIPlan03:

	lsr
	lsr
	lsr

	and #%11; msb of g
	tay
	
	lda PPU_bufferReady;		if buffer is full from last frame
	bne @return

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
		sec
:
	pha
	lda color2,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
		sec
:
	pha
	lda color1,x
	sbc @colorMutator,y
	bcs :+
		lda #$0f
		sec
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

	lda #TRUE
	sta PPU_bufferReady
@return:
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

BYTES_SCORE=24;2 function, 4 addresses, 18 bytes
PPU_renderScoreNMI:
	pla; set address
	sta PPUADDR
	pla
	sta PPUADDR

	pla; load 9 bytes
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

	pla; set address
	sta PPUADDR
	pla
	sta PPUADDR

	pla; load 9 bytes
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

	and #%110000; get high bits
	lsr
	lsr
	lsr
	lsr
	ora #%00100000; set bit above
	
	sta currentNameTable+1
	sta PPUADDR
	
	tya; make lobyte
	and #%1000
	asl
	asl
	asl
	asl
	sta currentNameTable
	tya
	and #%0111
	asl
	asl
	ora currentNameTable
	sta currentNameTable
	sta PPUADDR
	
	tya
	pha
	
	and #%00111000; last row is smaller
	cmp #%00111000
	bne @standardTile
@shorterTile:
	;save the 2 tiles
	lda (Lib_ptr0),y
	tay;y is now the 32x32 tile
	lda topLeft32,y
	sta tile16a
	lda topRight32,y
	sta tile16b
	
	ldy tile16a
	ldx tile16b
	lda topLeft16,y
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	
	lda topLeft16,x
	sta PPUDATA
	lda topRight16,x
	sta PPUDATA

	lda currentNameTable+1
	sta PPUADDR
	
	clc
	lda currentNameTable+0
	adc #32
	sta currentNameTable+0
	sta PPUADDR

	lda bottomLeft16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	
	lda bottomLeft16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	jmp @attributeByte

@standardTile:
	;save the 4 tiles
	lda (Lib_ptr0),y
	tay;y is now the 32x32 tile
	
	lda topLeft32,y
	sta tile16a
	lda topRight32,y
	sta tile16b
	lda bottomLeft32,y
	sta tile16c
	lda bottomRight32,y
	sta tile16d
	
	ldy tile16a
	ldx tile16b
	lda topLeft16,y
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda topLeft16,x
	sta PPUDATA
	lda topRight16,x
	sta PPUDATA

	lda currentNameTable+1
	sta PPUADDR

	clc
	lda currentNameTable+0
	adc #32
	sta currentNameTable+0
	sta PPUADDR
	
	lda bottomLeft16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	
	lda currentNameTable+1
	sta PPUADDR

	clc
	lda currentNameTable+0
	adc #32
	sta currentNameTable+0
	sta PPUADDR
	
	ldy tile16c
	ldx tile16d
	lda topLeft16,y
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda topLeft16,x
	sta PPUDATA
	lda topRight16,x
	sta PPUDATA
	
	lda currentNameTable+1
	sta PPUADDR

	clc
	lda currentNameTable+0
	adc #32
	sta currentNameTable+0
	sta PPUADDR
	
	lda bottomLeft16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
@attributeByte:
;get the tile
	lda #$23
	;store address (big endian)
	sta PPUADDR
	pla
	tay
	ora #%11000000
	sta PPUADDR
	lda (Lib_ptr0),y
	tay;y is tile itself
	lda tileAttributeByte,y
	sta PPUDATA
	rts


PPU_renderScreen:;	void(a)
	tax
	;clear vblank bit before write
	lda currentPPUSettings
	ora #INCREMENT_1
	sta PPUCTRL
	
	lda Scenes_screen,x
	tax

	lda Screens_l,x
	sta Lib_ptr0+0
	lda Screens_h,x
	sta Lib_ptr0+1

	ldx #00
@renderLoop:
	txa
	pha
	jsr render32; void(x)
	pla
	tax
	inx
	cpx #64
	bcc @renderLoop
	rts


PPU_resetScroll:
	lda #0
	sta PPU_scrollSpeed_h
	lda #64
	sta PPU_scrollSpeed_l

	lda #00
	sta xScroll
	sta yScroll_H
	sta yScroll_L
	rts

PPU_updateScroll:
	sec
	lda yScroll_L
	sbc PPU_scrollSpeed_l
	sta yScroll_L

	lda yScroll_H
	sta mathTemp
	sbc PPU_scrollSpeed_h
	cmp #240
	bcc :+
		clc
		adc #240
	:
	sta yScroll_H
	
	sec
	lda mathTemp
	sbc yScroll_H
	bcs :+
		lda mathTemp
		adc #240
		sbc yScroll_H
	:
	sta Scroll_delta

	rts


PPU_setScroll:
	
	lda currentMaskSettings
	sta PPUMASK
	lda #0; scroll x is 0
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
;swap stacks
	sws Main_stack, PPU_stack
;find how many hearts are empty
	sec
	lda #MAX_HEARTS
	sbc Player_hearts
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
	ldx Player_hearts
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

BYTES_HEARTS=9; 2 function, 2 address, 5 tiles
PPU_renderHeartsNMI:
	pla; set the address
	sta PPUADDR
	pla
	sta PPUADDR

	pla; load 5 tiles
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

.proc PPU_bombsToBuffer
BOMBS_MAX=3; max number of bombs
BOMBS_FULL_TILE=$eb; Graphic for full bomb	
BOMBS_EMPTY_TILE=$ec; Graphic for empty bomb		
BOMBS_ADDRESS=$2427; where it is rendered
;swap stacks
	sws Main_stack, PPU_stack
;find how many hearts are empty
	sec
	lda #BOMBS_MAX
	sbc Player_bombs
	beq @bombsFull;skip if bombs are full
		tax; else render the empty ones
	@emptyTileLoop:
	;fill in top with empty tiles
		lda #BOMBS_EMPTY_TILE
		pha
		dex
		bne @emptyTileLoop
@bombsFull:
;find how many full hearts there are
	ldx Player_bombs; if there are full bombs
	beq @bombsEmpty; else all bombs empty
	@fullTileLoop:
	;fill in full hearts
		lda #BOMBS_FULL_TILE
		pha
		dex
		bne @fullTileLoop
@bombsEmpty:
;addresses
	lda #<BOMBS_ADDRESS
	pha
	lda #>BOMBS_ADDRESS
	pha
;NMI render function pointer
	lda #>(PPU_renderBombsNMI-1)
	pha
	lda #<(PPU_renderBombsNMI-1)
	pha
;swap out the stacks
	sws PPU_stack, Main_stack
	rts
.endproc

BYTES_BOMBS=7; 2 function + 2 address + 3 tiles
PPU_renderBombsNMI:
	pla; set address
	sta PPUADDR
	pla
	sta PPUADDR

	pla; load 3 tiles
	sta PPUDATA
	pla
	sta PPUDATA
	pla
	sta PPUDATA
	rts


PPU_backgroundColorToBuffer:
	sws Main_stack, PPU_stack
	
	lda backgroundColor;		save background
	pha
	lda #>(PPU_drawBackground-1);	save draw routine
	pha
	lda #<(PPU_drawBackground-1)
	pha
	
	sws PPU_stack, Main_stack 
	rts

PPU_drawBackground:
ADDRESS_BACKGROUND	=	$3F00
	lda #>ADDRESS_BACKGROUND
	sta PPUADDR
	lda #<ADDRESS_BACKGROUND
	sta PPUADDR
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
	sta Lib_ptr0+0
	lda Portraits_H,y
	sta Lib_ptr0+0
	ldy #16-1;16 tiles
@loop:
	lda (Lib_ptr0),y
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


PPU_drawPressStart:
	lda #$2A
	sta PPUADDR
	lda #$4A
	sta PPUADDR
	ldx #00
@loop:
	lda @word,x
	sta PPUDATA
	inx
	cpx #$0B
	bcc @loop

	lda #$23
	sta PPUADDR
	lda #$E0
	sta PPUADDR

	ldx #32-1
@attribute:
	lda #%10101010
	sta PPUDATA
	dex
	bpl @attribute
	rts
@word:
	.byte $DF,$E1,$D4,$E2,$E2,$04,$E2,$E3,$D0,$E1,$E3
