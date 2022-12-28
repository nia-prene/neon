;constants
.globalzp MAX_ENEMY_BULLETS


;constructors
.global 	Bullets_new
.global 	Bullets_get
.global		Bullet_invisibility
.global		Bullet_type



;locals
.globalzp quickBulletX
.globalzp quickBulletY
.globalzp bulletType
.globalzp octant
.globalzp numberOfBullets
.globalzp bulletAngle

;attributes
.globalzp	isEnemyBulletActive
.global		enemyBulletXH
.global		enemyBulletXL
.global		enemyBulletYH
.global		enemyBulletYL
.global 	Bullets_ID
.global		Bullets_type
.global		Bullets_sprite
.global		Bullets_stagger
.global		Charm_speed_H
.global		Charm_speed_L
;functions
.global Bullets_tick
.global Bullets_aim
.global Bullets_clockwise
.global Bullets_toCharm
.global Charms_spin
.global Charms_suck


