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
	jsr prepareScene;moves all scene items from rom to ram
	jsr loadAllPalettes
	bit PPUSTATUS
@notInBlank:
	bit PPUSTATUS
	bpl @notInBlank

	lda #PPU_SETTINGS
	sta PPUCTRL
	bit PPUSTATUS
@vblankWait:
	bit PPUSTATUS
	bpl @vblankWait
	lda #MASK_SETTINGS
	sta PPUMASK
loop:
	jmp loop

nmi:
	sta accumulator
	sty yRegister
	stx xRegister
	lda #$00
	sta OAMADDR
	lda #$02
	sta OAMDMA
	;vblank code goes here
	lda accumulator
	ldy yRegister
	ldx xRegister
	rti

prepareScene:;(currentScene)
	lda #$00
	sta sceneIndex;index in scene object array (starting at 0)
	sta placeIndex;index in places object array (starting at 0)
	sta spritePaletteIndex;where we are in spritePalettes
	sta portraitPaletteIndex;where we are in portraitPalettes
	sta attributeByte;this will auto increment attributes for sprites

	jsr clearSprites;()
	jsr clearPlayfield;()
	jsr loadDefaultPalettes;()
	jsr getScenePointer;(currentScene
	jsr getTimeOfDay;(scenePointer)
	jsr getPlacePointer;(scenePointer)
	jsr unzipPlacePalettes;(placeIndex)

@paletteLoop:
	ldy sceneIndex
	lda (scenePointer), y;peak at the next person for sentinel
	cmp #$ff
	beq @endOfPeople;$ff is the sentinel for no more people
	jsr getPeoplePalettesPointer
	jsr unzipSpritePalettes
	jsr unzipPortraitPalettes
	jmp @paletteLoop
@endOfPeople:
@spriteLoop:
	ldy sceneIndex
	iny
	sty sceneIndex
	lda (scenePointer), y;
	cmp #$ff ;sentinel for end of sprites
	beq @endOfSprites
	jsr getSpritePointer
	jsr unzipSprites
	jmp @spriteLoop
@endOfSprites:
	rts


clearSprites:
	lda #$ff;clearing sprites with $ff puts them off screen
	ldx #$00
;clears the 1 page of data at "sprites" with ff
@clearSpritesLoop:
	sta sprites, x
	inx
	bne @clearSpritesLoop
	rts


clearPlayfield:
	ldx #$00
	lda #$00;clearing screens with $00 makes them blank tiles
;clears the page of memory at "screen1:"
@clearScreen1:
	sta screen1, x
	inx
	bne @clearScreen1
	;x is 0 and a is 0
;clears the page of memory at "screen2:"
@clearScreen2:
	sta screen2, x
	inx
	bne @clearScreen2
	rts


loadDefaultPalettes:
	lda #$00
	tax
	sta backgroundColor ;a is still #$00, grey default color
	lda #$2b;background palettes get set to ugly palette so its noticable if something goes wrong
;stores #$2b into the first 16 palette locations
@loadDefaultBackgroundPalette:
	sta palettes, x
	inx
	cpx #16; 16 colors 
	bne @loadDefaultBackgroundPalette
	ldy #$00
	;y is 0, x is position in palettes array
;loads colors 16 - 36 with default sprite colors. if there arent enough people to fill a scene, random people will have unique palettes
@loadDefaultSpritePalettes:
	lda defaultPalette, y
	sta palettes, x
	inx
	iny
	cpx #32 ;32 total colors
	bne @loadDefaultSpritePalettes
	rts



getScenePointer:
	lda currentScene
	;find pointer to scene. it is in an array of pointers at "scenes:"
	;because an address is 16 bit, the number needs to be doubled in order to find the correct address. 
	asl	;double the number
	tax
	lda scenes, x
	sta scenePointer
	lda scenes+1, x
	sta scenePointer+1
	rts


getTimeOfDay:
	;0th element in scene array is the time of day
	ldy sceneIndex
	lda (scenePointer), y
	sta backgroundColor
	iny
	sty sceneIndex
	rts


getPlacePointer:
	ldy sceneIndex; 2nd element in scene array is place
	lda (scenePointer), y
	asl	;double the number
	tax
	;get the pointer to the place and store it in "placePointer"
	lda places,x
	sta placePointer
	lda places+1, x
	sta placePointer+1
	iny
	sty sceneIndex
	rts


unzipPlacePalettes:
	;first element of the place
	ldy placeIndex
@backgroundPaletteLoop:
	;this loop loads all the palettes from the place pointed at, 12 in total
	lda (placePointer), y
	sta palettes, y
	iny
	cpy #12;posttest load 12 colors
	bne @backgroundPaletteLoop
	rts


;loadObjects

unzipPeoplePalettes:
	rts


getPeoplePalettesPointer:
	ldy sceneIndex
	lda (scenePointer), y
	iny
	sty sceneIndex
	asl
	tax
	;get the pointer to the person
	lda peoplePalettes,x
	sta peoplePalettesPointer
	lda peoplePalettes+1, x
	sta peoplePalettesPointer+1
	rts


unzipSpritePalettes:
	ldy #$00;sprite palettes are the 0th byte in peoplePalette arrays
	ldx spritePaletteIndex;this is where we are in loading palettes
@paletteLoop:
	lda (peoplePalettesPointer), y
	sta spritePalettes, x
	iny
	inx
	cpy #04
	bne @paletteLoop
	stx spritePaletteIndex
	rts

unzipPortraitPalettes:
	ldx portraitPaletteIndex
	ldy #04;this is where portrait palettes start in people palettes
@loadPaletteLoop:
	lda (peoplePalettesPointer), y
	sta portraitPalettes, x
	inx
	iny
	cpy #08;four colors, y was at 4
	bne @loadPaletteLoop
	stx portraitPaletteIndex
	rts


getSpritePointer:
	ldy sceneIndex
	lda (scenePointer), y;
	asl
	tax
	lda spriteData, x
	sta spritePointer
	lda spriteData+1, x
	sta spritePointer+1
	rts


unzipSprites:
	ldx spriteCounter
	ldy #$00 ;first element of the array
@spriteLoop:
	lda (spritePointer), y
	cmp #$ff
	beq @spriteIsDone
	sta sprites, x
	inx
	iny
	lda (spritePointer), y
	sta sprites, x
	inx
	iny
	lda (spritePointer), y
	ora attributeByte
	sta sprites, x
	inx
	iny
	lda (spritePointer), y
	sta sprites, x
	inx
	iny
	jmp @spriteLoop
@spriteIsDone:
	stx spriteCounter
	ldx attributeByte
	inx
	cpx #04
	beq @resetAttributeByte
	stx attributeByte
	rts
@resetAttributeByte:
	lda #$00
	sta attributeByte
	rts

;this subroutine transfers all palettes to the ppu
loadAllPalettes:
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
	tay
@mainPaletteLoop:
	lda palettes, x
	sta PPUDATA
	inx
	cpx #32
	bne @mainPaletteLoop
	lda #$3f
	sta PPUADDR
	tya 
	sta PPUADDR
	lda backgroundColor
	sta PPUDATA 
	rts
.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
