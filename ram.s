.segment "ZEROPAGE"
;pointers
loopTest: .res 1
tileToRender: .res 1
currentNameTable: .res 2
tile16a: .res 1
tile16b: .res 1
tile16c: .res 1
tile16d: .res 1
scenePointer: .res 2
placePointer: .res 2
;local variables/arguments
tile128a: .res 1
tile128b: .res 1
tile64a: .res 1
tile64b: .res 1
tile64c: .res 1
tile64d: .res 1

.segment "OAM"
;starts at $0200
sprites: .res 256

.segment "RAM"
;starts at $0300
;;;;;;;;;;;;;;;;;;
;;;metatile ram;;;
;;;;;;;;;;;;;;;;;;
halfScreens: .res 4
tiles128: .res 8
tiles64: .res 32
tiles32: .res 128
current128Column: .res 1
current64Column: .res 1
current32Column: .res 1
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

;;;;;;;;;;;;;;;
;;;scene ram;;;
;;;;;;;;;;;;;;;
currentDay: .res 1
currentScene: .res 1

