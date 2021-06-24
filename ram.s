.segment "ZEROPAGE"
test: .res 1
playerX: .res 1
playerY: .res 1
playerSpeed: .res 1
pressingShoot: .res 1
playerMetasprite: .res 1
MAX_PLAYER_BULLETS = 7
playerBulletX: .res MAX_PLAYER_BULLETS 
playerBulletY: .res MAX_PLAYER_BULLETS 
isPlayerBulletActive: .res MAX_PLAYER_BULLETS
playerBulletMetasprite: .res MAX_PLAYER_BULLETS
bulletToUpdate: .res 1
;highes level variables/arguments
xScroll: .res 1
yScroll: .res 1
nextScene: .res 1
currentScene: .res 1
currentPPUSettings: .res 1
currentMaskSettings: .res 1
objectToBuild: .res 1
enemyToUpdate: .res 1
currentHitboxColor: .res 1
;highest level flags
hasFrameBeenRendered: .res 1
willHitboxUpdate: .res 1
;local variables
sprite1LeftOrTop: .res 1
sprite1RightOrBottom: .res 1
sprite2LeftOrTop: .res 1
sprite2RightOrBottom: .res 1
buildX1: .res 1
buildX2: .res 1
buildX3: .res 1
buildX4: .res 1
buildY1: .res 1
buildY2: .res 1
buildAttribute: .res 1
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
;;;;;;;;;;;;;;
;;Sprites;;
;;;;;;;;;;;
;Enemies;
;;;;;;;;;
MAX_ENEMIES = 8
enemyWidth: .res MAX_ENEMIES
enemyHeight: .res MAX_ENEMIES
enemyHitboxX1: .res MAX_ENEMIES
enemyHitboxX2: .res MAX_ENEMIES
enemyType: .res MAX_ENEMIES
enemyBehaviorH: .res MAX_ENEMIES
enemyBehaviorL: .res MAX_ENEMIES
enemyX: .res MAX_ENEMIES
enemyY: .res MAX_ENEMIES
enemyMetasprite: .res MAX_ENEMIES
enemyHitboxY2: .res MAX_ENEMIES
isEnemyActive: .res MAX_ENEMIES
isEnemyHit: .res MAX_ENEMIES
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
