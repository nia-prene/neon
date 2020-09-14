.segment "ZEROPAGE"
;pointers
scenePointer: .res 2
placePointer: .res 2
peoplePointer: .res 2
;variables
accumulator: .res 1
xRegister: .res 1
yRegister: .res 1
personPaletteIndex: .res 1
personIndex: .res 1
.segment "OAM"
sprites: .res 256

.segment "RAM"
screen1: .res 256
screen2: .res 256
currentDay: .res 1
currentScene: .res 1
backgroundColor: .res 1
palettes: .res 24

