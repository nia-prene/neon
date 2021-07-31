.segment "ENEMIES"

BEACH_WAVES=0
levelWavesH:
	.byte >beachWaves
levelWavesL:
	.byte <beachWaves
;waves for each level as index to pointers
beachWaves:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
;pointers to individual enemy waves (below)
wavePointerH:
	.byte >wave0, >wave1
wavePointerL:
	.byte <wave0, <wave1
;individual enemy waves
wave0:
;first 3 bytes are bullet types
	.byte 0, 1, 0
;format string is (enemy, location) 0 is skip, null is terminate
	.byte 2, 16, 2, 20, 2, 12, NULL
wave1:
	.byte 0, 0, 0
	.byte 1, 15, 1, 05, 1, 25, $ff
;wave starting coordinates

;first byte is a burner byte so we can use zero flag to denote empty slot
romEnemyBehaviorH:
	.byte NULL, >enemy01, >enemy02
romEnemyBehaviorL:
	.byte NULL, <enemy01-1, <enemy02-1
romEnemyMetasprite:
	.byte NULL, TARGET_SPRITE, TARGET_SPRITE
romEnemyHPH:
	.byte NULL, 00, 00
romEnemyHPL:
	.byte NULL, 10, 10
;the type determines the width, height, and how it is built in oam
romEnemyType: 
	.byte NULL, 01, 01
romEnemyWidth:
	.byte 8, 16, 16, 32
romEnemyHeight:
	.byte 16, 16, 32, 16
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
	adc #32
	sta enemyYL,x
	lda enemyYH,x
	adc #01
;clear if off screen
	bcs @clearEnemy
	sta enemyYH,x
;save y value
	pha
;isolate bit 7, shift to bit 0
	and #%10000000
	rol
	rol
;save on y
	tay
;retrieve 
	pla
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
	bcs @clearEnemy
	rts
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts

enemy02:
	pla
	tax
;move down at a rate of 1.5 px per frame
	clc
	lda enemyYL,x
	adc #128
	sta enemyYL,x
	lda enemyYH,x
	adc #01
;clear if off screen
	bcs @clearEnemy
	sta enemyYH,x
;save y value
	pha
	cmp #%00010000
	beq @shoot
@returnFromShoot:
	rol
	rol
	and #%00000001
	sta mathTemp
	pla
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
	bcs @clearEnemy
	rts
@clearEnemy:
	lda #FALSE
	sta isEnemyActive,x
	rts
@shoot:
;save the x
	adc #16
	sta quickBulletY
	lda enemyXH,x
	adc #8
	sta quickBulletX
	txa
	pha
	jsr aimBullet
	lsr
	pha
	lsr
	ora #%10000000
	jsr initializeEnemyBullet
	pla
	adc #4
	pha
	jsr initializeEnemyBullet
	pla
	sbc #8
	jsr initializeEnemyBullet
	pla
	tax
	pla
	pha
	jmp @returnFromShoot
