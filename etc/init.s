;this module initializes the nes to a known state, sets OAM buffer to address $0200 and jumps to the main: subroutine.

reset:
    sei		;ignore IRQs
	cld		;disable decimal mode
    ldx #$40
    stx JOY2	;disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
    inx        ; now X = 0
	stx PPUCTRL; disable NMI
    stx PPUMASK; disable rendering
    stx DMC_FREQ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that @vblankwait1
    ; does not exit immediately.
    bit PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
@vblankwait1:  
	bit PPUSTATUS
    bpl @vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
@clrmem:
	lda $00
	sta $000,x	;clear ram
	sta $100,x
	sta $300,x
	sta $400,x
	sta $500,x
	sta $600,x
	sta $700,x
	lda #$ff
	sta $200,x	;hide sprites at lower right
	lda #$00
	inx
	bne @clrmem
	
@vblankwait2:	;second of two vblank waits for ppu stabilization
	bit PPUSTATUS
	bpl @vblankwait2

	lda OAM_LOCATION
	sta OAMDMA;set up OAM DMA at $0200
	nop
	jsr main;return from interrupt
