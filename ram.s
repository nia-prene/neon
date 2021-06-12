.segment "ZEROPAGE"
playerX: .res 1
playerY: .res 1
playerSpeed: .res 1
pressingShoot: .res 1
MAX_PLAYER_BULLETS = 7
playerBulletX: .res MAX_PLAYER_BULLETS 
playerBulletY: .res MAX_PLAYER_BULLETS 
isPlayerBulletActive: .res MAX_PLAYER_BULLETS
bulletToUpdate: .res 1
test: .res 1
;highes level variables/arguments
xScroll: .res 1
yScroll: .res 1
hasFrameBeenRendered: .res 1
nextScene: .res 1
currentScene: .res 1
currentPPUSettings: .res 1
currentMaskSettings: .res 1
objectToBuild: .res 1
;local variables
oamOffset: .res 1
metaspriteToBuild: .res 1
buildTile0: .res 1
buildAttribute0: .res 1
buildTile1: .res 1
buildAttribute1: .res 1
buildTile2: .res 1
buildAttribute2: .res 1
buildTile3: .res 1
buildAttribute3: .res 1
buildX1: .res 1
buildX2: .res 1
buildY1: .res 1
buildY2: .res 1
buildWidth: .res 1
buildHeight: .res 1
buildTotal: .res 1
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
controllers:
	controller1: .res 1
	controller2: .res 1
.segment "OAM"
;starts at $0200
oam: .res 256

.segment "RAM"
;starts at $0300
;;;;;;;;;;;;
;;Sprites;;;
;;;;;;;;;;;;
MAX_OBJECTS = 31
isActive: .res MAX_OBJECTS
spriteX: .res MAX_OBJECTS 
spriteY: .res MAX_OBJECTS 
metasprite: .res MAX_OBJECTS 
;;;;;;;;;;;;
;;;screen;;;
;;;;;;;;;;;;
currentScreen: .res 1
tiles128: .res 4
tiles64: .res 16
tiles32: .res 64

;;;;;;;;;;;
;;;clock;;;
;;;;;;;;;;;
seconds: .res 1
minutes: .res 1
hours: .res 1
days: .res 1

;;;;;;;;;;;;;;
;;;Palettes;;;
;;;;;;;;;;;;;;
BACKGROUND_COLOR = $1D;black
color1: .res 8
color2: .res 8
color3: .res 8
