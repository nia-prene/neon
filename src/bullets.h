;constants
.globalzp MAX_ENEMY_BULLETS

;locals
.globalzp quickBulletX
.globalzp quickBulletY
.globalzp bulletType
.globalzp octant
.globalzp numberOfBullets
.globalzp bulletAngle
.globalzp Bullets_fastForwardFrames

;attributes
.globalzp isEnemyBulletActive
.global enemyBulletHitbox1
.global enemyBulletHitbox2
.global enemyBulletBehaviorH
.global enemyBulletBehaviorL
.global enemyBulletXH
.global enemyBulletXL
.global enemyBulletYH
.global enemyBulletYL
.global enemyBulletMetasprite
.global enemyBulletBehaviorH
.global enemyBulletBehaviorL
.global Bullets_ID


;functions
.global Bullets_new
.global Bullets_get
.global Bullets_tick
.global Bullets_aim
.global Bullets_clockwise
.global Bullets_toCharm
.global Charms_spin
.global Charms_suck
