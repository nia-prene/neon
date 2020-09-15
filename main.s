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
	bpl @notInBlank

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
	;first we need to clear data from the old scene
	lda #$ff;clearing sprites with $ff puts them off screen
	ldx #$00
@clearSprites:
	sta sprites, x
	inx
	bne @clearSprites

	lda #$00;clearing screens with $00 makes them blank tiles
	;x is 0 and a is 0
@clearScreen1:
	sta screen1, x
	inx
	bne @clearScreen1
	;x is 0 and a is 0
@clearScreen2:
	sta screen2, x
	inx
	bne @clearScreen2
	;x is 0 and a is 0
	;next we are going to fill our palettes with some default values
	sta backgroundColor ;a is still #$00, grey default color
	lda #$2b
	ldy #$00
@loadDefaultBackgroundPalette:
	sta palettes, x
	inx
	cpx #12 ;background palettes get set to ugly palette so its noticable
	bne @loadDefaultBackgroundPalette
	ldy #$00
	;y is 0, x is position in palettes array
@loadDefaultSpritePalettes:
	lda defaultPalette, y
	sta palettes, x
	inx
	iny
	cpx #24 ;12 colors
	bne @loadDefaultSpritePalettes
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
	;0th element in scene array is the time of day
	ldy #$00
	lda (scenePointer), y
	sta backgroundColor
	iny
	;the next element is the place, decoded as an index in an array of pointers
	lda (scenePointer), y
	;"places:" is an array of addresses. the number needs to be doubled to find the pointer
	asl	;double the number
	tax
	;get the pointer to the place and store it in "placePointer"
	lda places,x
	sta placePointer
	lda places+1, x
	sta placePointer+1
	;first element of the place
	ldy #$00;byte 0 in places is palettes
@backgroundPaletteLoop:
	;this loop loads all the palettes from the place pointed at, 9 in total
	lda (placePointer), y
	sta palettes, y
	iny
	cpy #$09;posttest load 9 colors
	bne @backgroundPaletteLoop
;loadObjects
;loadPeople(people)
;variables personPaletteIndex personIndex
;these variables persist so that the sprite palette index and the current person is not lost
	;personPaletteIndex = 12 (this is where we are in the palettes as a whole
	;personIndex = 1 (people start on the 1st byte of a scene array
	lda #12;through the background palettes. the rest start at #12
	sta personPaletteIndex
	lda #$02;people start at byte 2 in scene array
	sta personIndex
	lda #$00
	sta portraitCounter;this helps get all the portraits of all the people in the portrait array
@loadPeopleLoop:
	lda personIndex
	sec
	sbc #$02;althogh our people start at $2 in array, the first person will need their attribute byte
	sta attributeByte
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

	ldy #$00;sprite palettes are the 0th byte in people arrays
	ldx personPaletteIndex;this is where we are in loading palettes
@loadSpritePalette:
	lda (peoplePointer), y
	sta palettes, x
	iny
	inx
	stx personPaletteIndex
	cpy #$03
	bne @loadSpritePalette
	;y is at 3
	ldx portraitCounter
@loadPortraitPalette:
	;lets get the portraits too, y is at three and portraits start at 3
	lda (peoplePointer), y
	sta portraitPalettes, x
	inx
	iny
	cpy #06;three colors
	bne @loadPortraitPalette
	stx portraitCounter
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



