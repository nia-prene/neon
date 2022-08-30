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
.global isEnemyBulletActive
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

.global Charms_getActive


;functions
.global Bullets_new
.global Bullets_newGroup
.global Enemy_Bullets
.global aimBullet
.global updateEnemyBullets
.global Bullets_clockwise
.global Bullets_toCharm
.global Charms_spin
.global Charms_suck
