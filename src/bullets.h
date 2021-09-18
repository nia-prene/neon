;constants
.globalzp MAX_ENEMY_BULLETS

;locals
.globalzp quickBulletX
.globalzp quickBulletY
.globalzp bulletType
.globalzp octant
.globalzp numberOfBullets
.globalzp bulletAngle

;attributes
.global enemyBulletHitboxX1
.global enemyBulletHitboxX2
.global enemyBulletHitboxY1
.global enemyBulletHitboxY2
.global enemyBulletBehaviorH
.global enemyBulletBehaviorL
.global enemyBulletXH
.global enemyBulletXL
.global enemyBulletYH
.global enemyBulletYL
.global enemyBulletMetasprite
.global enemyBulletWidth
.global isEnemyBulletActive

;functions
.global aimBullet
.global initializeEnemyBullet 
.global updateEnemyBullets

