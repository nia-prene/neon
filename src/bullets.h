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

;functions
.global Enemy_Bullet
.global Enemy_Bullets
.global aimBullet
.global updateEnemyBullets
.global Bullets_toCoins
