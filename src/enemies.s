.include "lib.h"
.include "enemies.h"
.include "player.h"
.include "sprites.h"
.include "playerbullets.h"
.include "bullets.h"
.include "pickups.h"

.zeropage
totalDamage: .res 1
.data
MAX_ENEMIES = 16
enemyXH: .res MAX_ENEMIES
enemyXL: .res MAX_ENEMIES
enemyYH: .res MAX_ENEMIES
enemyYL: .res MAX_ENEMIES
enemyHPH: .res MAX_ENEMIES
enemyHPL: .res MAX_ENEMIES
i: .res MAX_ENEMIES
j: .res MAX_ENEMIES
enemyBehaviorH: .res MAX_ENEMIES
enemyBehaviorL: .res MAX_ENEMIES
enemyMetasprite: .res MAX_ENEMIES
enemyHitboxX1: .res MAX_ENEMIES
enemyHitboxX2: .res MAX_ENEMIES
enemyHitboxY2: .res MAX_ENEMIES
enemyWidth: .res MAX_ENEMIES
enemyPalette: .res MAX_ENEMIES
isEnemyActive: .res MAX_ENEMIES

.code
initializeEnemy:;void (a,x,y)
;places enemy from slot onto enemy array and screen coordinates
;arguments
;a - enemy
;x - x coordinate
;y - y coordinate
	;save enemy
	pha
	;save x
	txa
	pha
	;save y
	tya
	pha
	;save x coordinate
	jsr getAvailableEnemy
	bcc @enemiesFull
	;returns x - available enemy
	;retains y, enemy
	;get y coordinate
	pla
	sta enemyYH,x
	;get x coordinate
	pla
	sta enemyXH,x
	;copy data from rom
	pla
	tay
;copy function pointers
	lda romEnemyBehaviorH,y
	sta enemyBehaviorH,x
	lda romEnemyBehaviorL,y
	sta enemyBehaviorL,x
;copy metasprites
	lda romEnemyMetasprite,y
	sta enemyMetasprite,x
;copy hp
	lda romEnemyHPH,y
	sta enemyHPH,x
	lda romEnemyHPL,y
	sta enemyHPL,x
;copy hitboxes
	lda romEnemyHitboxX1,y
	sta enemyHitboxX1,x
	lda romEnemyHitboxX2,y
	sta enemyHitboxX2,x
	lda romEnemyHitboxY2,y
	sta enemyHitboxY2,x
	lda romEnemyWidth,y
	sta enemyWidth,x
	lda #0
;clear palette modifier
	sta enemyPalette,x
;it is helpful to have i at zero, and j at 128 so patterns can mirror
	sta i,x
	lda #128	
	sta j,x
	rts
@enemiesFull:
	pla
	pla
	pla
	rts

getAvailableEnemy:
;finds open enemy slot, returns offset, sets slot to active
;arguments - none
;returns
;x - enemy offset
	ldx #MAX_ENEMIES-1
@enemySlotLoop:
	lda isEnemyActive,x
;if enemy is inactive return offset
	beq @returnEnemy
;x--
	dex
;while x >= 0
	bpl @enemySlotLoop
	clc
	rts
@returnEnemy:
	lda #TRUE
;set enemy to active
	sta isEnemyActive,x
;set carry to success
	sec
	rts

updateEnemies:
;arguments - none
;returns - none
	ldx #MAX_ENEMIES-1
@enemyUpdateLoop:
;update active enemies
	lda isEnemyActive,x
	beq @nextEnemy
;save index
	txa
	pha
;push function onto stack
	lda enemyBehaviorH,x
	pha
	lda enemyBehaviorL,x
	pha
@nextEnemy:
;x--
	dex
;while x >= 0
	bpl @enemyUpdateLoop
	rts

.align $100
Enemies_isAlive:
;compares enemies to the player bullets and determines if they overlap
;arguments
;x - enemy to check'
;y - player bullet
;clear out total damage
	lda #0
	sta totalDamage
	sta enemyPalette,x
	ldy #MAX_PLAYER_BULLETS-1
@bulletLoop:
;find an active bullet
	lda isActive,y
	beq @nextBullet
;find the X distance between bullet and enemy
	sec
	lda bulletX,y
	sbc enemyXH,x
	bcs @playerGreaterX
;twos compliment if negative number
	eor #%11111111
@playerGreaterX:
;continue if closer than enemy width
	cmp enemyWidth,x
	bcs @nextBullet
;find the Y distance between bullet and enemy
	sec
	lda bulletY,y
	sbc enemyYH,x
	bcs @playerGreaterY
;twos compliment if negative number
	eor #%11111111
@playerGreaterY:
;continue if closer than height
	cmp enemyHitboxY2,x
	bcs @nextBullet
;calculate left and right side of player bullet
	lda bulletX,y
	sta sprite1LeftOrTop
	adc PlayerBullet_width,y
	sta sprite1RightOrBottom
;calculate left and right side of enemy
	lda enemyXH,x
	adc enemyHitboxX1,x
	sta sprite2LeftOrTop
	adc enemyHitboxX2,x
	sta sprite2RightOrBottom
;check for overlap, continue if true
	jsr checkCollision
	bcc @nextBullet
;calculate top and bottom of player bullet
	lda bulletY,y
	sta sprite1LeftOrTop
	adc #16;height of all player bullets
	sta sprite1RightOrBottom
;calculate top and bottom of enemy
	lda enemyYH,x
	sta sprite2LeftOrTop
	adc enemyHitboxY2,x
	sta sprite2RightOrBottom
;check for overlap
	jsr checkCollision
	bcc @nextBullet
;mark bit 1 so bullet is cleared next frame
	lda #%11
	sta isActive,y
	sta enemyPalette,x
;get a running total of the damage sustained
	clc
	lda PlayerBullet_damage,y
	adc totalDamage
	sta totalDamage
@nextBullet:
	dey
	bpl @bulletLoop
;if the result is negative, enemy is dead, carry is cleared
	sec
	lda enemyHPL,x
	sbc totalDamage
	sta enemyHPL,x
	lda enemyHPH,x
	sbc #0
	sta enemyHPH,x
	rts

Enemies_explodeSmall:
	pla
	tax
;lasts for 16 frames
	lda i,x
	cmp #16
	bcs @clear
;divide by 4 to find animation frame
	lsr
	lsr
	tay
	lda @animationFrames,y
	sta enemyMetasprite,x
	inc i,x
	rts
@clear:
	lda j,x
	bne @dropPowerup
	lda #FALSE
	sta isEnemyActive,x
;pickup algo here
	rts
@dropPowerup:
	lda #<(Pickups_movePowerup-1)
	sta enemyBehaviorL,x
	lda #>Pickups_movePowerup
	sta enemyBehaviorH,x
	rts
@animationFrames:
	.byte SPRITE0A, SPRITE0B ,SPRITE0C ,SPRITE0D


.macro explode	size, powerUp
	lda #0
	sta enemyPalette,x
	sta i,x
	lda powerUp
	sta j,x
.if (.xmatch ({size}, 0))
	lda #<(Enemies_explodeSmall-1)
	sta enemyBehaviorL,x
	lda #>Enemies_explodeSmall
	sta enemyBehaviorH,x
.else 
	.error "explosion needs size"
.endif
	rts
.endmacro
ENEMY01=1
ENEMY02=2
ENEMY03=3
ENEMY04=4
ENEMY05=5
.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot
romEnemyBehaviorH:
	.byte NULL, >(enemy01-1), >(enemy02-1), >(enemy03-1), >(enemy04-1), >(enemy05-1)
romEnemyBehaviorL:
	.byte NULL, <(enemy01-1), <(enemy02-1), <(enemy03-1), <(enemy04-1), <(enemy05-1)
romEnemyMetasprite:
	.byte NULL, SPRITE0F, SPRITE0F, SPRITE10, SPRITE10, SPRITE14
romEnemyHPH:
	.byte NULL, 00, 00, 00, 00, 00
romEnemyHPL: 
	.byte NULL, 02, 02, 25, 25, 192
;the type determines the width, height, and how it is built in oam
romEnemyWidth:
	.byte NULL, 16, 16, 16, 16, 16
romEnemyHitboxX1:
	.byte NULL, 02, 02, 02, 02, 02
romEnemyHitboxX2:
	.byte NULL, 12, 12, 12, 12, 12
romEnemyHitboxY2:
	.byte NULL, 14, 14, 30, 30, 14

.proc enemy01
SHOT_Y_OFFSET=16
SHOT_X_OFFSET=4
Y_SPEED_H=1
Y_SPEED_L=128
;placed along top (y = 0), ascends and pulls slightly to the right
	pla
	tax
	clc
;move down at a rate of 1.5 px per frame
	lda enemyYL,x
	adc #Y_SPEED_L
	sta enemyYL,x
	lda enemyYH,x
	adc #Y_SPEED_H
;clear if offscreen
	bcs @clearEnemy
	sta enemyYH,x
;isolate bit 7, shift to bit 0
	rol
	rol
	and #%00000001
;save on y
	tay
	lda enemyYH,x
;isolate bits 0-6, shift them left
	asl
	clc
;X coordinate = x + |0000000y yyyyyyy0| created from y coordinate hibyte
	adc enemyXL,x
	sta enemyXL,x
	tya
	adc enemyXH,x
	bcs @clearEnemy
	sta enemyXH,x
	jsr Enemies_isAlive 
	bcc @enemyHit
	lda i,x
	bne @return
	lda enemyYH,x
	cmp #32
	bcc @shoot
@return:
	rts
@enemyHit:
	explode	0, #FALSE
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@shoot:
	lda #TRUE
	sta i,x
	clc
	lda enemyYH,x
	adc #SHOT_Y_OFFSET
	sta quickBulletY
	lda enemyXH,x
	adc #SHOT_X_OFFSET
	sta quickBulletX
	jsr aimBullet
	and #%11111100
	ora #%00000001
	pha
	clc
	adc #5
	pha
	sec
	sbc #8
	pha
	lda #3
	sta numberOfBullets
	jmp Enemy_Bullets
.endproc
.proc enemy02
SHOT_Y_OFFSET=16
SHOT_X_OFFSET=4
Y_SPEED_H=1
Y_SPEED_L=128
	pla
	tax
	clc
	lda enemyYL,x
	adc #Y_SPEED_L
	sta enemyYL,x
	lda enemyYH,x
	adc #Y_SPEED_H
;clear if off screen
	bcs @clearEnemy
	sta enemyYH,x
	rol
	rol
	and #%00000001
	sta mathTemp
	lda enemyYH,x
	asl
	sta mathTemp+1
;X coordinate = x - |0000000y yyyyyyy0| created from y coordinate hibyte
	sec
	lda enemyXL,x
	sbc mathTemp+1
	sta enemyXL,x
	lda enemyXH,x
	sbc mathTemp
;clear if it goes off screen
	bcc @clearEnemy
	sta enemyXH,x
;check if shot
	jsr Enemies_isAlive 
	bcc @enemyHit
	lda i,x
	bne @return
	lda enemyYH,x
	cmp #32
	bcc @shoot
@return:
	rts
@enemyHit:
	explode	0, #FALSE
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@shoot:
	lda #TRUE
	sta i,x
	clc
	lda enemyYH,x
	adc #SHOT_Y_OFFSET
	sta quickBulletY
	lda enemyXH,x
	adc #SHOT_X_OFFSET
	sta quickBulletX
	jsr aimBullet
;select bullet type 2
	and #%11111100
	ora #%00000001
	pha
;shoot two more bullets on side
	clc
	adc #5
	pha
	sec
	sbc #8
	pha
	lda #3
	sta numberOfBullets
	jmp Enemy_Bullets
.endproc

.proc enemy03
SHOT_Y_OFFSET=24
SHOT_X_OFFSET=4
X_SPEED_H=0
X_SPEED_L=32
Y_SPEED_H=0
Y_SPEED_L=4
	pla
	tax
;move along x axis
	clc
	lda enemyXL,x
	adc #X_SPEED_L
	sta enemyXL,x
	lda enemyXH,x
	adc #X_SPEED_H
	bcs @clearEnemy
	sta enemyXH,x
;move along y axis
	sec
	lda enemyYL,x
	sbc #Y_SPEED_L
	sta enemyYL,x
	lda enemyYH,x
	sbc #Y_SPEED_H
	bcc @clearEnemy
;get the animation frame (2 possible) tied to y position
	sta enemyYH,x
	and #%00000001
	tay
	lda @animationFrames,y
	sta enemyMetasprite,x
	jsr Enemies_isAlive 
	bcc @enemyDestroyed
	jmp @shoot
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@enemyDestroyed:
	explode 0, #TRUE
@shoot:
	clc
	lda j,x
	adc #1
	sta j,x
;shoots when bit 3 off, every other frame
	and #%00001001
	beq @shooting
	rts
@shooting:
	clc
	lda enemyYH,x
	adc #SHOT_Y_OFFSET
	pha
	lda enemyXH,x
	adc #SHOT_X_OFFSET
	pha
	clc
	lda i,x
	adc #4
	sta i,x
	pha
	jmp Enemy_Bullet
@animationFrames:
	.byte SPRITE10, SPRITE11
.endproc

.proc enemy04
SHOT_Y_OFFSET=24
SHOT_X_OFFSET=4
X_SPEED_H=0
X_SPEED_L=32
Y_SPEED_H=0
Y_SPEED_L=4
	pla
	tax
	sec
	lda enemyXL,x
	sbc #X_SPEED_L
	sta enemyXL,x
	lda enemyXH,x
	sbc #X_SPEED_H
	bcc @clearEnemy
	sta enemyXH,x
	sec
	lda enemyYL,x
	sbc #Y_SPEED_L
	sta enemyYL,x
	lda enemyYH,x
	sbc #Y_SPEED_H
	bcc @clearEnemy
	sta enemyYH,x
	jsr Enemies_isAlive 
	bcc @enemyHit
	jmp @shoot
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@enemyHit:
	explode 0, #TRUE
@shoot:
	clc
	lda i,x
	adc #1
	sta i,x
	and #%00001001
	beq @shooting
	rts
@shooting:
	sec	
	lda enemyYH,x
	adc #SHOT_Y_OFFSET
	pha
	lda enemyXH,x
	adc #SHOT_X_OFFSET
	pha
	sec
	lda j,x
	sbc #4
	sta j,x
	pha
	jmp Enemy_Bullet
.endproc

.proc enemy05
	pla
	tax
	lda isEnemyActive,x
	ror
	ror
	bcs @phase2
	lda enemyYH,x
	adc #2
	sta enemyYH,x
;when y is greater than 32, set phase 2
	cmp #32
	bcc @return
	rol isEnemyActive,x
@return:
	rts
@phase2:
	ror
	ror
	bcs @phase3
	lda i,x
	adc #1
	sta i,x
	bmi @underWater
	and #%01100000
	lsr
	lsr
	lsr
	lsr
	lsr
	tay
	lda @emergingAnimation,y
	sta enemyMetasprite,x
	jsr Enemies_isAlive
	bcc @destroyed
	lda i,x
	and #%00000001
	bne @return
	clc
	lda enemyYH,x
	adc #16
	pha
	lda enemyXH,x
	adc #4
	pha
	lda j,x
	adc #36
	sta j,x
	and #%01111111
	pha
	jmp Enemy_Bullet
@underWater:
	and #%01100000
	lsr
	lsr
	lsr
	lsr
	lsr
	tay
	lda @submergingAnimation,y
	sta enemyMetasprite,x
	lda #0
	sta enemyPalette,x
	lda i,x
	cmp #192
	bne @return
	sec
	rol isEnemyActive,x
	rts
@phase3:
	lda enemyYH,x
	adc #3
	sta enemyYH,x
	bcc @return
	lda #FALSE
	sta isEnemyActive,x
	rts
@destroyed:
	explode 0, #TRUE
@submergingAnimation:
	.byte SPRITE13, SPRITE14, SPRITE14, SPRITE14 
@emergingAnimation:
	.byte SPRITE13, SPRITE12, SPRITE12, SPRITE12 
.endproc
