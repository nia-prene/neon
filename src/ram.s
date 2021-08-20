.segment "ZEROPAGE"
test: .res 1
iFrames: .res 1
playerXH: .res 1
playerXL: .res 1
playerYH: .res 1
playerYL: .res 1
playerSpeedH: .res 1
playerSpeedL: .res 1
playerRateOfFire: .res 1
pressingShoot: .res 1
playerMetasprite: .res 1
MAX_PLAYER_BULLETS = 9
playerBulletX: .res MAX_PLAYER_BULLETS 
playerBulletY: .res MAX_PLAYER_BULLETS 
isPlayerBulletActive: .res MAX_PLAYER_BULLETS
playerBulletMetasprite: .res MAX_PLAYER_BULLETS
;highes level variables/arguments
xScroll: .res 1
yScroll: .res 1
nextScene: .res 1
currentScene: .res 1
currentPPUSettings: .res 1
currentMaskSettings: .res 1
waveRate: .res 1
mathTemp: .res 2
;highest level flags
hasFrameBeenRendered: .res 1
;local variables
quickBulletX: .res 1
quickBulletY: .res 1
bulletType: .res 4
octant: .res 1
enemyIndex: .res 1
waveIndex: .res 1
sprite1LeftOrTop: .res 1
sprite1RightOrBottom: .res 1
sprite2LeftOrTop: .res 1
sprite2RightOrBottom: .res 1
buildX: .res 1
buildY: .res 1
buildPalette: .res 1
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
;pointers
spritePointer: .res 2
levelWavePointer: .res 2
wavePointer: .res 2
.segment "OAM"
;starts at $0200
oam: .res 256

.segment "RAM"
;starts at $0300
;;;;;;;;;;;
;;Sprites;;
;;;;;;;;;;;
;;;;;;;;;
;Bullets;
;;;;;;;;;
MAX_ENEMY_BULLETS=56
enemyBulletHitboxX1: .res MAX_ENEMY_BULLETS
enemyBulletHitboxX2: .res MAX_ENEMY_BULLETS
enemyBulletHitboxY1: .res MAX_ENEMY_BULLETS
enemyBulletHitboxY2: .res MAX_ENEMY_BULLETS
enemyBulletBehaviorH: .res MAX_ENEMY_BULLETS
enemyBulletBehaviorL: .res MAX_ENEMY_BULLETS
enemyBulletXH: .res MAX_ENEMY_BULLETS
enemyBulletXL: .res MAX_ENEMY_BULLETS
enemyBulletYH: .res MAX_ENEMY_BULLETS
enemyBulletYL: .res MAX_ENEMY_BULLETS
enemyBulletMetasprite: .res MAX_ENEMY_BULLETS
enemyBulletWidth: .res MAX_ENEMY_BULLETS
isEnemyBulletActive: .res MAX_ENEMY_BULLETS
;;;;;;;;;
;Enemies;
;;;;;;;;;
MAX_ENEMIES = 8
enemyXH: .res MAX_ENEMIES
enemyXL: .res MAX_ENEMIES
enemyYH: .res MAX_ENEMIES
enemyYL: .res MAX_ENEMIES
enemyHPH: .res MAX_ENEMIES
enemyHPL: .res MAX_ENEMIES
i: .res MAX_ENEMIES
j: .res MAX_ENEMIES
k: .res MAX_ENEMIES
enemyType: .res MAX_ENEMIES
enemyBehaviorH: .res MAX_ENEMIES
enemyBehaviorL: .res MAX_ENEMIES
enemyMetasprite: .res MAX_ENEMIES
enemyHitboxX1: .res MAX_ENEMIES
enemyHitboxX2: .res MAX_ENEMIES
enemyHitboxY2: .res MAX_ENEMIES
enemyWidth: .res MAX_ENEMIES
enemyHeight: .res MAX_ENEMIES
isEnemyActive: .res MAX_ENEMIES
enemyStatus: .res MAX_ENEMIES
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
BACKGROUND_COLOR = $0f;black
color1: .res 8
color2: .res 8
color3: .res 8
