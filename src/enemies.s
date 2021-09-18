.include "lib.h"
.include "enemies.h"
.include "sprites.h"
.include "playerbullets.h"
.include "bullets.h"

.zeropage
totalDamage: .res 1
.data
MAX_ENEMIES = 10
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
	lda romEnemyBehaviorH,y
	sta enemyBehaviorH,x
	lda romEnemyBehaviorL,y
	sta enemyBehaviorL,x
	lda romEnemyMetasprite,y
	sta enemyMetasprite,x
	lda romEnemyHPH,y
	sta enemyHPH,x
	lda romEnemyHPL,y
	sta enemyHPL,x
	lda #0
;clear variables
	sta i,x
;clear palette modifier
	sta enemyPalette,x
;set j to 128
	sec
	ror
	sta j,x
;get enemy type
	lda romEnemyType,y
;use enemy type to get hardcoded attributes
	tay
	lda romEnemyHitboxX1,y
	sta enemyHitboxX1,x
	lda romEnemyHitboxX2,y
	sta enemyHitboxX2,x
	lda romEnemyHitboxY2,y
	sta enemyHitboxY2,x
	lda romEnemyWidth,y
	sta enemyWidth,x
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
wasEnemyHit:
;compares enemies to the player bullets and determines if they overlap
;arguments
;x - enemy to check
;y is player bullet, start with 0
	lda #0
	sta totalDamage
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
	eor #%11111111
@playerGreaterY:
;continue if closer than height
	cmp enemyHitboxY2,x
	bcs @nextBullet
;calculate left and right side of player bullet
	lda bulletX,y
	sta sprite1LeftOrTop
	adc #08
	sta sprite1RightOrBottom
;calculate left and right side of enemy
	lda enemyXH,x
	adc enemyHitboxX1,x
	sta sprite2LeftOrTop
	adc enemyHitboxX2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @nextBullet
;calculate top and bottom of player bullet
	lda bulletY,y
	sta sprite1LeftOrTop
	adc #16
	sta sprite1RightOrBottom
;calculate top and bottom of enemy
	lda enemyYH,x
	sta sprite2LeftOrTop
	adc enemyHitboxY2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @nextBullet
	lda #%11
	sta isActive,y
	clc
	lda totalDamage,y
	adc totalDamage
	sta totalDamage
@nextBullet:
	dey
	bpl @bulletLoop
	lda totalDamage
	rts

.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot
romEnemyBehaviorH:
	.byte NULL, >enemy01, >enemy02, >enemy03, >enemy04, >enemy05
romEnemyBehaviorL:
	.byte NULL, <(enemy01-1), <(enemy02-1), <(enemy03-1), <(enemy04-1), <(enemy05-1)
romEnemyMetasprite:
	.byte NULL, TARGET_SPRITE, TARGET_SPRITE, TARGET_SPRITE, TARGET_SPRITE, TARGET_SPRITE
romEnemyHPH:
	.byte NULL, 00, 00, 0, 0
romEnemyHPL: .byte NULL, 6, 6, 50, 50
;the type determines the width, height, and how it is built in oam
romEnemyType: 
	.byte NULL, 01, 01, 02, 02
;TYPES:
romEnemyWidth:
	.byte 8, 16, 16, 32
romEnemyHitboxX1:
	.byte 1, 2, 2, 2
romEnemyHitboxX2:
	.byte 6, 12, 12, 30
romEnemyHitboxY2:
	.byte 14, 14, 30, 14

enemy01:
;placed along top (y = 0), ascends and pulls slightly to the right
	pla
	tax
	clc
;move down at a rate of 1.5 px per frame
	lda enemyYL,x
	adc #64
	sta enemyYL,x
	lda enemyYH,x
	adc #01
;save
	pha
;clear if offscreen
	bcs @clearEnemy
	sta enemyYH,x
;isolate bit 7, shift to bit 0
	rol
	rol
	and #%00000001
;save on y
	tay
;retrieve 
	pla
;save for shooting
	pha
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
	jsr wasEnemyHit
	bne @enemyHit
	lda #0
	sta enemyPalette,x
	pla
	and #%11111111
	cmp #%00010000
	beq @shoot
	rts
@enemyHit:
@clearEnemy:
	pla
	lda #FALSE
	sta isEnemyActive,x
	rts
@shoot:
	adc #10
	sta quickBulletY
	lda enemyXH,x
	adc #8
	sta quickBulletX
	jsr aimBullet;returns bullet angle
	lda bulletAngle
	ora #%00000001
	and #%11111101
	pha
	lda bulletAngle
	adc #5
	and #%11111110
	pha
	sbc #8
	and #%11111110
	pha
	lda #3
	sta numberOfBullets
	jmp initializeEnemyBullet

enemy02:
	pla
	tax
	clc
	lda enemyYL,x
	adc #64
	sta enemyYL,x
	lda enemyYH,x
	adc #01
	pha
;clear if off screen
	bcs @clearEnemy
	sta enemyYH,x
	rol
	rol
	and #%00000001
	sta mathTemp
	pla
	pha
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
	jsr wasEnemyHit
	bne @enemyHit
	pla
	and #%11111111
	cmp #%00010000
	beq @shoot
	rts
@enemyHit:
@clearEnemy:
	pla
	lda #FALSE
	sta isEnemyActive,x
	rts
@shoot:
	adc #10
	sta quickBulletY
	lda enemyXH,x
	adc #8
	sta quickBulletX
	jsr aimBullet;returns bullet angle
	lda bulletAngle
	ora #%00000001
	and #%11111101
	pha
	lda bulletAngle
	adc #5
	and #%11111110
	pha
	sbc #8
	and #%11111110
	pha
	lda #3
	sta numberOfBullets
	jmp initializeEnemyBullet


enemy03:
	pla
	tax
	clc
	lda enemyXL,x
	adc #32
	sta enemyXL,x
	lda enemyXH,x
	adc #0
	bcs @clearEnemy
	sta enemyXH,x
	sec
	lda enemyYL,x
	sbc #4
	sta enemyYL,x
	lda enemyYH,x
	sbc #0
	bcc @clearEnemy
	sta enemyYH,x
	jsr wasEnemyHit
	bne @enemyHit
	lda #%0
	sta enemyPalette,x
	jmp @shoot
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@enemyHit:
	dec enemyHPL,x
	beq @clearEnemy
	lda #%11
	sta enemyPalette,x
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
	lda i,x
	adc #4
	sta i,x
	pha
	lda enemyYH,x
	adc #16
	sta quickBulletY
	lda enemyXH,x
	adc #8
	sta quickBulletX
	lda #1
	sta numberOfBullets
	jmp initializeEnemyBullet

enemy04:
	pla
	tax
	sec
	lda enemyXL,x
	sbc #32
	sta enemyXL,x
	lda enemyXH,x
	sbc #0
	bcc @clearEnemy
	sta enemyXH,x
	sec
	lda enemyYL,x
	sbc #4
	sta enemyYL,x
	lda enemyYH,x
	sbc #0
	bcc @clearEnemy
	sta enemyYH,x
	jsr wasEnemyHit
	bne @enemyHit
	lda #%0
	sta enemyPalette,x
	jmp @shoot
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@enemyHit:
	dec enemyHPL,x
	beq @clearEnemy
	lda #%11
	sta enemyPalette,x
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
	lda j,x
	sbc #4
	sta j,x
	lsr
	pha
	lda enemyYH,x
	adc #16
	sta quickBulletY
	lda enemyXH,x
	adc #8
	bcc @noOverflow
	lda #$ff
@noOverflow:
	sta quickBulletX
	lda #1
	sta numberOfBullets
	jmp initializeEnemyBullet
enemy05:
