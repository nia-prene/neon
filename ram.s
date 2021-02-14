.segment "ZEROPAGE"
;local variables/arguments
testVariable: .res 1
testLoopVariable: .res 1
;position in object array
objectToInitialize: .res 1
objectToUpdate: .res 1
;Sprite Coordinate calculations
spriteTileYValues:
yValue0: .res 1
yValue1: .res 1
yValue2: .res 1
yValue3: .res 1
yValue4: .res 1
yValue5: .res 1
spriteTileXValues:
xValue0: .res 1
xValue1: .res 1
xValue2: .res 1
xValue3: .res 1
xValue4: .res 1
;todo sceneToRender
currentScene: .res 1
;nmi variables
currentPPUSettings: .res 1
currentMaskSettings: .res 1
vBlankScrollX: .res 1
;tile rendering variables
;todo
currentNameTable: .res 2
tileToRender: .res 1
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
;flags
hasFrameBeenRendered: .res 1
isInBlank: .res 1
.segment "OAM"
;starts at $0200
oam: .res 256

.segment "RAM"
;starts at $0300
;;;;;;;;;;;;;;;
;;object ram;;;
;;;;;;;;;;;;;;;;;;
;8 sprite objects;
;;;;;;;;;;;;;;;;;;
inputs: .res 8
spriteObject: .res 8
previousMetaSprite: .res 8
currentMetaSprite: .res 8
oamOffset: .res 8
spriteTileTotal: .res 8
metaSpriteWidth: .res 8
metaSpriteHeight: .res 8
;input addresses
inputsH: .res 8
inputsL: .res 8
;controller inputs
previousX: .res 8
spriteX: .res 8
previousY: .res 8
spriteY: .res 8


;;;;;;;;;;;
;;;tiles;;;
;;;;;;;;;;;
currentScreen: .res 1
tiles128: .res 4
tiles64: .res 16
tiles32: .res 64
current128Column: .res 1
current64Column: .res 1
current32Column: .res 1
;;;;;;;;;;;;;;
;;;palettes;;;
;;;;;;;;;;;;;;
backgroundColor: .res 1
color0: .res 8
color1: .res 8
color2: .res 8
color3: .res 8
;;;;;;;;;;;
;;;clock;;;
;;;;;;;;;;;
seconds: .res 1
minutes: .res 1
hours: .res 1
;;;;;;;;;;;;
;parameters;
;;;;;;;;;;;;
