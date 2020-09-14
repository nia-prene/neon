.include "constants.s"
.segment "HEADER"
.include "header.s"
.include "ram.s"
.segment "STARTUP"
.include "init.s"
.segment "CODE"
main:
	lda #$00
	sta currentScene
	jsr unzipScene;unzip refers to the process of moving rom files to ram
	jsr loadAllPalettes;loading refers to the act of using in the program
@notInBlank:
	bit PPUSTATUS
	bmi @notInBlank

	lda PPU_SETTINGS
	sta PPUCTRL
@vblankWait:
	bit PPUSTATUS
	bpl @vblankWait
	lda MASK_SETTINGS
	sta PPUMASK
loop:
	jmp loop

nmi:
	sta accumulator
	sty yRegister
	stx xRegister
	lda OAM_LOCATION
	sta OAMDMA
	;vblank code goes here
	lda accumulator
	ldy yRegister
	ldx xRegister
	rti

;unzipScene(currentScene)
unzipScene:
	;get scene number
	lda currentScene
	;find pointer to scene. it is in an array of pointers at "scenes:"
	;because an address is 16 bit, the number needs to be doubled in order to find the correct address. 
	asl	;double the number
	tax
	lda scenes, x
	sta scenePointer
	lda scenes+1, x
	sta scenePointer+1
	;loadPlace
	;first element in scene array is the place the scene is located in
	ldy #$00	
	lda (scenePointer), y
	;same thing there. "places:" is an array of addresses. the number needs to be doubled to find the pointer
	asl	;double the number
	tax
	;get the pointer to the place and store it in "placePointer"
	lda places,x
	sta placePointer
	lda places+1, x
	sta placePointer+1
	;first element of the place
	ldy #$00
	lda (placePointer), y
	;this is the background color
	sta backgroundColor
	iny;next element is the palettes
	ldx #$00
@backgroundPaletteLoop:
	;this loop loads all the palettes from the place pointed at, 9 in total
	lda (placePointer), y
	sta palettes, x
	iny
	inx
	cpx #$09;posttest load 9 colors
	bne @backgroundPaletteLoop
;loadObjects
;loadPeople(people)
;variables personPaletteIndex personIndex
;these variables persist so that the sprite palette index and the current person is not lost
	;personPaletteIndex = 12 (this is where we are in the palettes as a whole
	;personIndex = 1 (people start on the 1st byte of a scene array
	lda #12;
	sta personPaletteIndex
	lda #$01
	sta personIndex
@loadPeopleLoop:
	ldy personIndex
	lda (scenePointer), y
	bmi @endOfPeople;$ff is the sentinel for no more people
	asl
	tax
	;get the pointer to the person
	lda people,x
	sta peoplePointer
	lda people+1, x
	sta peoplePointer+1
	;increase person index for next loop before value is lost
	iny
	sty personIndex

	ldy #$00
	ldx personPaletteIndex
@loadPersonPalette:
	lda (peoplePointer), y
	sta palettes, x
	iny
	inx
	stx personPaletteIndex
	cpy #$03
	bne @loadPersonPalette
	jmp @loadPeopleLoop
@endOfPeople:
	rts
	;loadConversations(conversation)

	;this subroutine transfers all palettes to the ppu
loadAllPalettes:
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #$00
@mainPaletteLoop:
	ldy #$00
	lda backgroundColor
	sta PPUDATA
@loadPaletteLoop:
	lda palettes, x
	sta PPUDATA
	iny
	inx
	cpy #$03
	bne @loadPaletteLoop
	cpx #24
	bne @mainPaletteLoop
	rts
.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"



