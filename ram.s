.segment "ZEROPAGE"
;local variables/argumentas
testVariable: .res 1
testLoopVariable: .res 1
nextFreeOamOffset: .res 1
collisionXCoordinate: .res 1
collisionYCoordinate: .res 1
tileCollisionData: .res 1
metaTileToCheckCollision: .res 1
totalTileCounter: .res 1
tilePaletteAttribute: .res 1
xVal0: .res 1
xVal1: .res 1
xVal2: .res 1
xVal3: .res 1
xVal4: .res 1
yVal0: .res 1
yVal1: .res 1
yVal2: .res 1
yVal3: .res 1
yVal4: .res 1
yUpdateHeightCounter: .res 1
xUpdateHeightCounter: .res 1
controllers:
	controller1: .res 1
	controller2: .res 1
objectToUpdate: .res 1
;Sprite Coordinate calculations
;todo sceneToRender
nextScene: .res 1
currentScene: .res 1
;nmi variables
currentPPUSettings: .res 1
currentMaskSettings: .res 1
;tile rendering variables
;todo
currentNameTable: .res 2
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
.segment "OAM"
;starts at $0200
oam: .res 256

.segment "RAM"
;starts at $0300
;;;;;;;;;;;;;;;
;;object ram;;;
;;;;;;;;;;;;;;;;;;
;8 sprites objects;
;;;;;;;;;;;;;;;;;;
oamOffset: .res 8
objectID: .res 8
inputs: .res 2
currentMetaSprite: .res 8
nextMetaSprite: .res 8
spriteBehaviorsH: .res 8
spriteBehaviorsL: .res 8
metaSpriteTileTotal: .res 8
metaSpriteWidth: .res 8
metaSpriteHeight: .res 8
metaSpritePalette: .res 8
metaSpriteHitboxX1: .res 8
metaSpriteHitboxX2: .res 8
metaSpriteHitboxY1: .res 8
metaSpriteHitboxY2: .res 8
XCollisionData: .res 8
YCollisionData: .res 8
previousXCollisionData: .res 8
previousYCollisionData: .res 8

;input addresses
inputsH: .res 8
inputsL: .res 8
;controller inputs
previousX: .res 8
spriteX: .res 8
previousY: .res 8
spriteY: .res 8
;flags
didXChange: .res 8
didYChange: .res 8
didTilesChange: .res 8

;;;;;;;;;;;;
;;;screen;;;
;;;;;;;;;;;;
BACKGROUND_COLOR = $1D;black
currentScreen: .res 1
tiles128: .res 4
tiles64: .res 16
tiles32: .res 64
color1: .res 8
color2: .res 8
color3: .res 8
;;;;;;;;;;;
;;;clock;;;
;;;;;;;;;;;
seconds: .res 1
minutes: .res 1
hours: .res 1
days: .res 1
