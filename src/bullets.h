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
.global enemyBulletHitbox1
.global enemyBulletHitbox2
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
.global Enemy_Bullet
.global Enemy_Bullets
.global aimBullet
.global updateEnemyBullets

