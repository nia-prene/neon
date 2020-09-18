.segment "ZEROPAGE"
;pointers
scenePointer: .res 2
placePointer: .res 2
peoplePalettesPointer: .res 2
spritePointer: .res 2
;variables
accumulator: .res 1
xRegister: .res 1
yRegister: .res 1
sceneIndex: .res 1
placeIndex: .res 1
spritePaletteIndex: .res 1
portraitPaletteIndex: .res 1
attributeByte: .res 1
spriteCounter: .res 1
.segment "OAM"
sprites: .res 256

.segment "RAM"
screen1: .res 256
screen2: .res 256

;starts at $0500
currentDay: .res 1
currentScene: .res 1
backgroundColor: .res 1
palettes:
	backgroundPalettes:
		backgroundPalette1: .res 4
		backgroundPalette2: .res 4
		backgroundPalette3: .res 4
		currentPortrait: .res 4
	spritePalettes:
		spritePalette1: .res 4
		spritePalette2: .res 4
		spritePalette3: .res 4
		spritePalette4: .res 4
portraitPalettes: .res 16
player: .res 24
