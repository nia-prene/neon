.include "bullets.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "bombs.h"
.include "enemies.h"

BULLETS_VARIETIES=8
MAX_ENEMY_BULLETS=129

.zeropage
isEnemyBulletActive: .res MAX_ENEMY_BULLETS
;arguments
Bullets_fastForwardFrames:.res 1

;pointers
Bullets_move: .res 2

;locals
b:.res 1
octant: .res 1
bulletAngle: .res 1
Charms_active: .res 1
quickBulletX: .res 1
quickBulletY: .res 1


.data

Bullets_ID: .res MAX_ENEMY_BULLETS
enemyBulletXH: .res MAX_ENEMY_BULLETS
enemyBulletXL: .res MAX_ENEMY_BULLETS
enemyBulletYH: .res MAX_ENEMY_BULLETS
enemyBulletYL: .res MAX_ENEMY_BULLETS

.code

	
Bullets_new:; c(x,y) | x
	
	pha; save ID
	jsr Bullets_get;c,y(void) | x
	pla; restore ID
	bcc @bulletsFull;returns clear if full
		sta Bullets_ID,y
		
		lda enemyXH,x; coordinate copy
		sta enemyBulletXH,y
		lda enemyYH,x
		sta enemyBulletYH,y;
	
		lda Bullets_fastForwardFrames; invisibility frames
		sta isEnemyBulletActive,y
	
@bulletsFull:
	rts


Bullets_get:; c,y() | x
;returns x - active offset
;returns carry clear if full
	
	inc b
	lda b
	ror
	bcc @forward

	ldy #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,y
	beq @return
		dey
		bpl @bulletLoop
		clc;mark full
		rts
@return:
	sec ;mark success
	rts


@forward:
	ldy #00
@forwardLoop:
	lda isEnemyBulletActive,y
	beq @forwardReturn
		iny
		cpy #MAX_ENEMY_BULLETS
		bcc @forwardLoop
		clc;mark full
		rts
@forwardReturn:
	sec ;mark success
	rts

Bullets_tick:; void()

	ldx #MAX_ENEMY_BULLETS-1; for each bullet

Bullets_moveLoop:
	lda isEnemyBulletActive,x
	beq Bullets_tickDown;skip inactive bullets
		
		cmp #TRUE; if higher than true
		beq @visible

			sbc #1; decrease invisibility timer
			sta isEnemyBulletActive,x
	@visible:

		ldy Bullets_ID,x

		lda Bullets_move_L,y
		sta Bullets_move+0
		lda Bullets_move_H,y
		sta Bullets_move+1

		jmp (Bullets_move); void (a) | x
		
Bullets_tickDown:

	dex ;x--
	bpl Bullets_moveLoop;while x>=0
	
	rts


Charms_spin:; (void)
;pushes all bullet offsets and functions onto stack and returns
	
	ldx #MAX_ENEMY_BULLETS-1; for x

@charmLoop:
	lda isEnemyBulletActive,x; if active
	beq @skipCharm;skip inactive
		
		cmp #1
		beq @visible
			
			lda #FALSE; clear invisible bullets
			sta isEnemyBulletActive,x
			jmp @skipCharm

	@visible:

		clc; make them fall down
		lda enemyBulletYH,x
		adc #1
		bcc :+
			lda #255
		:sta enemyBulletYH,x

@skipCharm:
	
	dex ;x--
	bpl @charmLoop;while x>=0
	
	rts


; returns Bullet aimed at player
Bullets_aim:; a(x) | x

	lda enemyXH,x
	sta quickBulletX
	lda enemyYH,x
	sta quickBulletY

	stx xReg

	sec
	lda Player_xPos_H
	sbc quickBulletX
	bcs *+4
	eor #$ff
	tax

	rol octant

	lda Player_yPos_H
	sec
	sbc quickBulletY
	bcs *+4
	eor #$ff
	tay

	rol octant

	sec
	lda log2_tab,x
	sbc log2_tab,y
	bcc *+4
	eor #$ff
	tax

	lda octant
	rol
	and #%111
	tay

	lda atan_tab,x
	eor octant_adjust,y

	ldx xReg

	rts; a

Bullets_clockwise:;void()

	ldy #MAX_ENEMY_BULLETS-1

@bulletLoop:

	lda isEnemyBulletActive,y
	beq @nextBullet

		clc
		lda Bullets_ID,y
		adc #4
		sta Bullets_ID,y

@nextBullet:

	dey
	bpl @bulletLoop

	rts

Charms_suck:
	lda #FALSE
	sta Charms_active

	ldx #MAX_ENEMY_BULLETS-1

@charmLoop:

	lda isEnemyBulletActive,x
	beq @nextCharm
		
		sta Charms_active
		sec
		lda Player_xPos_H
		sbc enemyBulletXH,x
		bcs @playerXGreater

			eor #%11111111; ones compliment
			tay
			jmp @moveLeft

	@playerXGreater:
	
		tay
		jmp @moveRight

	@doY:

		sec
		lda Player_yPos_H
		sbc enemyBulletYH,x
		bcs @playerYGreater

			eor #%11111111; ones compliment
			tay
			jmp @moveUp

	@playerYGreater:

		tay
		jmp @moveDown

@nextCharm:
	
	dex
	bpl @charmLoop

	lda Charms_active
	rts; a

@moveLeft:

	lda enemyBulletXL,x
	sbc Charm_speed_L,y
	sta enemyBulletXL,x
	
	lda enemyBulletXH,x
	sbc Charm_speed_H,y
	sta enemyBulletXH,x

	jmp @doY

@moveRight:

	lda enemyBulletXL,x
	adc Charm_speed_L,y
	sta enemyBulletXL,x
	
	lda enemyBulletXH,x
	adc Charm_speed_H,y
	sta enemyBulletXH,x
	
	jmp @doY

@moveDown:

	lda enemyBulletYL,x
	adc Charm_speed_L,y
	sta enemyBulletYL,x
	
	lda enemyBulletYH,x
	adc Charm_speed_H,y
	sta enemyBulletYH,x

	jmp @nextCharm

@moveUp:

	lda enemyBulletYL,x
	sbc Charm_speed_L,y
	sta enemyBulletYL,x
	
	lda enemyBulletYH,x
	sbc Charm_speed_H,y
	sta enemyBulletYH,x

	jmp @nextCharm

.rodata

Bullets_spriteBank:
	.byte SPRITE02,SPRITE02,SPRITE02,SPRITE02
;the following attributes are the bullets type. The bullet type is stored with the enemy wave, so that each bullet can change sprite, width, etc throughout gameplay at the beginning of each enemy wave, where it will remain constant until the next enemy wave is loaded.
romEnemyBulletHitbox1:
	.byte 2, 3
romEnemyBulletHitbox2:
	.byte 4, 12
Bullets_diameterROM:
	.byte 8, 16	
romEnemyBulletMetasprite:
	.byte SPRITE02,SPRITE03

.macro bulletFib quadrant, X_H, X_L, Y_H, Y_L,
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	lda enemyBulletYL,x
	sbc Y_L
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	lda enemyBulletYL,x
	adc Y_L
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYL,x
	lda enemyBulletYH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sbc Y_H
	bcc @clearBullet
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	adc Y_H
	bcs @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYH,x
	lda enemyBulletXL,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc X_L
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc X_L
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXL,x
	lda enemyBulletXH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc X_H
	bcs @clearBullet
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc X_H
	bcc @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXH,x
	jmp Bullets_tickDown
@clearBullet:
	jmp Bullet_clear
.endmacro
Bullet_clear:
	lda #FALSE
	sta isEnemyBulletActive,x
	jmp Bullets_tickDown


bullet00:
	bulletFib 3, #2, #128, #0, #0
bullet01:
	bulletFib 3, #2, #191, #0, #17
bullet02:
	bulletFib 3, #2, #255, #0, #37
bullet03:
	bulletFib 3, #3, #61, #0, #61
bullet04:
	bulletFib 3, #2, #124, #0, #62
bullet05:
	bulletFib 3, #2, #186, #0, #86
bullet06:
	bulletFib 3, #2, #247, #0, #112
bullet07:
	bulletFib 3, #3, #51, #0, #142
bullet08:
	bulletFib 3, #2, #115, #0, #124
bullet09:
	bulletFib 3, #2, #174, #0, #154
bullet0A:
	bulletFib 3, #2, #232, #0, #186
bullet0B:
	bulletFib 3, #3, #33, #0, #221
bullet0C:
	bulletFib 3, #2, #100, #0, #185
bullet0D:
	bulletFib 3, #2, #156, #0, #220
bullet0E:
	bulletFib 3, #2, #211, #1, #2
bullet0F:
	bulletFib 3, #3, #8, #1, #43
bullet10:
	bulletFib 3, #2, #79, #0, #244
bullet11:
	bulletFib 3, #2, #131, #1, #29
bullet12:
	bulletFib 3, #2, #182, #1, #72
bullet13:
	bulletFib 3, #2, #231, #1, #118
bullet14:
	bulletFib 3, #2, #52, #1, #45
bullet15:
	bulletFib 3, #2, #100, #1, #91
bullet16:
	bulletFib 3, #2, #146, #1, #138
bullet17:
	bulletFib 3, #2, #190, #1, #189
bullet18:
	bulletFib 3, #2, #20, #1, #99
bullet19:
	bulletFib 3, #2, #63, #1, #149
bullet1A:
	bulletFib 3, #2, #104, #1, #201
bullet1B:
	bulletFib 3, #2, #143, #1, #255
bullet1C:
	bulletFib 3, #1, #238, #1, #150
bullet1D:
	bulletFib 3, #2, #21, #1, #203
bullet1E:
	bulletFib 3, #2, #57, #2, #3
bullet1F:
	bulletFib 3, #2, #90, #2, #61
bullet20:
	bulletFib 3, #1, #196, #1, #196
bullet21:
	bulletFib 3, #1, #229, #1, #253
bullet22:
	bulletFib 3, #2, #3, #2, #57
bullet23:
	bulletFib 3, #2, #31, #2, #117
bullet24:
	bulletFib 3, #1, #150, #1, #238
bullet25:
	bulletFib 3, #1, #177, #2, #42
bullet26:
	bulletFib 3, #1, #201, #2, #104
bullet27:
	bulletFib 3, #1, #223, #2, #168
bullet28:
	bulletFib 3, #1, #99, #2, #20
bullet29:
	bulletFib 3, #1, #120, #2, #82
bullet2A:
	bulletFib 3, #1, #138, #2, #146
bullet2B:
	bulletFib 3, #1, #154, #2, #211
bullet2C:
	bulletFib 3, #1, #45, #2, #52
bullet2D:
	bulletFib 3, #1, #60, #2, #116
bullet2E:
	bulletFib 3, #1, #72, #2, #182
bullet2F:
	bulletFib 3, #1, #81, #2, #248
bullet30:
	bulletFib 3, #0, #244, #2, #79
bullet31:
	bulletFib 3, #0, #253, #2, #144
bullet32:
	bulletFib 3, #1, #2, #2, #211
bullet33:
	bulletFib 3, #1, #4, #3, #22
bullet34:
	bulletFib 3, #0, #185, #2, #100
bullet35:
	bulletFib 3, #0, #187, #2, #166
bullet36:
	bulletFib 3, #0, #186, #2, #232
bullet37:
	bulletFib 3, #0, #182, #3, #43
bullet38:
	bulletFib 3, #0, #124, #2, #115
bullet39:
	bulletFib 3, #0, #120, #2, #181
bullet3A:
	bulletFib 3, #0, #112, #2, #247
bullet3B:
	bulletFib 3, #0, #101, #3, #57
bullet3C:
	bulletFib 3, #0, #62, #2, #124
bullet3D:
	bulletFib 3, #0, #51, #2, #190
bullet3E:
	bulletFib 3, #0, #37, #2, #255
bullet3F:
	bulletFib 3, #0, #20, #3, #63
bullet40:
	bulletFib 4, #0, #0, #2, #128
bullet41:
	bulletFib 4, #0, #17, #2, #191
bullet42:
	bulletFib 4, #0, #37, #2, #255
bullet43:
	bulletFib 4, #0, #61, #3, #61
bullet44:
	bulletFib 4, #0, #62, #2, #124
bullet45:
	bulletFib 4, #0, #86, #2, #186
bullet46:
	bulletFib 4, #0, #112, #2, #247
bullet47:
	bulletFib 4, #0, #142, #3, #51
bullet48:
	bulletFib 4, #0, #124, #2, #115
bullet49:
	bulletFib 4, #0, #154, #2, #174
bullet4A:
	bulletFib 4, #0, #186, #2, #232
bullet4B:
	bulletFib 4, #0, #221, #3, #33
bullet4C:
	bulletFib 4, #0, #185, #2, #100
bullet4D:
	bulletFib 4, #0, #220, #2, #156
bullet4E:
	bulletFib 4, #1, #2, #2, #211
bullet4F:
	bulletFib 4, #1, #43, #3, #8
bullet50:
	bulletFib 4, #0, #244, #2, #79
bullet51:
	bulletFib 4, #1, #29, #2, #131
bullet52:
	bulletFib 4, #1, #72, #2, #182
bullet53:
	bulletFib 4, #1, #118, #2, #231
bullet54:
	bulletFib 4, #1, #45, #2, #52
bullet55:
	bulletFib 4, #1, #91, #2, #100
bullet56:
	bulletFib 4, #1, #138, #2, #146
bullet57:
	bulletFib 4, #1, #189, #2, #190
bullet58:
	bulletFib 4, #1, #99, #2, #20
bullet59:
	bulletFib 4, #1, #149, #2, #63
bullet5A:
	bulletFib 4, #1, #201, #2, #104
bullet5B:
	bulletFib 4, #1, #255, #2, #143
bullet5C:
	bulletFib 4, #1, #150, #1, #238
bullet5D:
	bulletFib 4, #1, #203, #2, #21
bullet5E:
	bulletFib 4, #2, #3, #2, #57
bullet5F:
	bulletFib 4, #2, #61, #2, #90
bullet60:
	bulletFib 4, #1, #196, #1, #196
bullet61:
	bulletFib 4, #1, #253, #1, #229
bullet62:
	bulletFib 4, #2, #57, #2, #3
bullet63:
	bulletFib 4, #2, #117, #2, #31
bullet64:
	bulletFib 4, #1, #238, #1, #150
bullet65:
	bulletFib 4, #2, #42, #1, #177
bullet66:
	bulletFib 4, #2, #104, #1, #201
bullet67:
	bulletFib 4, #2, #168, #1, #223
bullet68:
	bulletFib 4, #2, #20, #1, #99
bullet69:
	bulletFib 4, #2, #82, #1, #120
bullet6A:
	bulletFib 4, #2, #146, #1, #138
bullet6B:
	bulletFib 4, #2, #211, #1, #154
bullet6C:
	bulletFib 4, #2, #52, #1, #45
bullet6D:
	bulletFib 4, #2, #116, #1, #60
bullet6E:
	bulletFib 4, #2, #182, #1, #72
bullet6F:
	bulletFib 4, #2, #248, #1, #81
bullet70:
	bulletFib 4, #2, #79, #0, #244
bullet71:
	bulletFib 4, #2, #144, #0, #253
bullet72:
	bulletFib 4, #2, #211, #1, #2
bullet73:
	bulletFib 4, #3, #22, #1, #4
bullet74:
	bulletFib 4, #2, #100, #0, #185
bullet75:
	bulletFib 4, #2, #166, #0, #187
bullet76:
	bulletFib 4, #2, #232, #0, #186
bullet77:
	bulletFib 4, #3, #43, #0, #182
bullet78:
	bulletFib 4, #2, #115, #0, #124
bullet79:
	bulletFib 4, #2, #181, #0, #120
bullet7A:
	bulletFib 4, #2, #247, #0, #112
bullet7B:
	bulletFib 4, #3, #57, #0, #101
bullet7C:
	bulletFib 4, #2, #124, #0, #62
bullet7D:
	bulletFib 4, #2, #190, #0, #51
bullet7E:
	bulletFib 4, #2, #255, #0, #37
bullet7F:
	bulletFib 4, #3, #63, #0, #20
bullet80:
	bulletFib 1, #2, #128, #0, #0
bullet81:
	bulletFib 1, #2, #191, #0, #17
bullet82:
	bulletFib 1, #2, #255, #0, #37
bullet83:
	bulletFib 1, #3, #61, #0, #61
bullet84:
	bulletFib 1, #2, #124, #0, #62
bullet85:
	bulletFib 1, #2, #186, #0, #86
bullet86:
	bulletFib 1, #2, #247, #0, #112
bullet87:
	bulletFib 1, #3, #51, #0, #142
bullet88:
	bulletFib 1, #2, #115, #0, #124
bullet89:
	bulletFib 1, #2, #174, #0, #154
bullet8A:
	bulletFib 1, #2, #232, #0, #186
bullet8B:
	bulletFib 1, #3, #33, #0, #221
bullet8C:
	bulletFib 1, #2, #100, #0, #185
bullet8D:
	bulletFib 1, #2, #156, #0, #220
bullet8E:
	bulletFib 1, #2, #211, #1, #2
bullet8F:
	bulletFib 1, #3, #8, #1, #43
bullet90:
	bulletFib 1, #2, #79, #0, #244
bullet91:
	bulletFib 1, #2, #131, #1, #29
bullet92:
	bulletFib 1, #2, #182, #1, #72
bullet93:
	bulletFib 1, #2, #231, #1, #118
bullet94:
	bulletFib 1, #2, #52, #1, #45
bullet95:
	bulletFib 1, #2, #100, #1, #91
bullet96:
	bulletFib 1, #2, #146, #1, #138
bullet97:
	bulletFib 1, #2, #190, #1, #189
bullet98:
	bulletFib 1, #2, #20, #1, #99
bullet99:
	bulletFib 1, #2, #63, #1, #149
bullet9A:
	bulletFib 1, #2, #104, #1, #201
bullet9B:
	bulletFib 1, #2, #143, #1, #255
bullet9C:
	bulletFib 1, #1, #238, #1, #150
bullet9D:
	bulletFib 1, #2, #21, #1, #203
bullet9E:
	bulletFib 1, #2, #57, #2, #3
bullet9F:
	bulletFib 1, #2, #90, #2, #61
bulletA0:
	bulletFib 1, #1, #196, #1, #196
bulletA1:
	bulletFib 1, #1, #229, #1, #253
bulletA2:
	bulletFib 1, #2, #3, #2, #57
bulletA3:
	bulletFib 1, #2, #31, #2, #117
bulletA4:
	bulletFib 1, #1, #150, #1, #238
bulletA5:
	bulletFib 1, #1, #177, #2, #42
bulletA6:
	bulletFib 1, #1, #201, #2, #104
bulletA7:
	bulletFib 1, #1, #223, #2, #168
bulletA8:
	bulletFib 1, #1, #99, #2, #20
bulletA9:
	bulletFib 1, #1, #120, #2, #82
bulletAA:
	bulletFib 1, #1, #138, #2, #146
bulletAB:
	bulletFib 1, #1, #154, #2, #211
bulletAC:
	bulletFib 1, #1, #45, #2, #52
bulletAD:
	bulletFib 1, #1, #60, #2, #116
bulletAE:
	bulletFib 1, #1, #72, #2, #182
bulletAF:
	bulletFib 1, #1, #81, #2, #248
bulletB0:
	bulletFib 1, #0, #244, #2, #79
bulletB1:
	bulletFib 1, #0, #253, #2, #144
bulletB2:
	bulletFib 1, #1, #2, #2, #211
bulletB3:
	bulletFib 1, #1, #4, #3, #22
bulletB4:
	bulletFib 1, #0, #185, #2, #100
bulletB5:
	bulletFib 1, #0, #187, #2, #166
bulletB6:
	bulletFib 1, #0, #186, #2, #232
bulletB7:
	bulletFib 1, #0, #182, #3, #43
bulletB8:
	bulletFib 1, #0, #124, #2, #115
bulletB9:
	bulletFib 1, #0, #120, #2, #181
bulletBA:
	bulletFib 1, #0, #112, #2, #247
bulletBB:
	bulletFib 1, #0, #101, #3, #57
bulletBC:
	bulletFib 1, #0, #62, #2, #124
bulletBD:
	bulletFib 1, #0, #51, #2, #190
bulletBE:
	bulletFib 1, #0, #37, #2, #255
bulletBF:
	bulletFib 1, #0, #20, #3, #63
bulletC0:
	bulletFib 2, #0, #0, #2, #128
bulletC1:
	bulletFib 2, #0, #17, #2, #191
bulletC2:
	bulletFib 2, #0, #37, #2, #255
bulletC3:
	bulletFib 2, #0, #61, #3, #61
bulletC4:
	bulletFib 2, #0, #62, #2, #124
bulletC5:
	bulletFib 2, #0, #86, #2, #186
bulletC6:
	bulletFib 2, #0, #112, #2, #247
bulletC7:
	bulletFib 2, #0, #142, #3, #51
bulletC8:
	bulletFib 2, #0, #124, #2, #115
bulletC9:
	bulletFib 2, #0, #154, #2, #174
bulletCA:
	bulletFib 2, #0, #186, #2, #232
bulletCB:
	bulletFib 2, #0, #221, #3, #33
bulletCC:
	bulletFib 2, #0, #185, #2, #100
bulletCD:
	bulletFib 2, #0, #220, #2, #156
bulletCE:
	bulletFib 2, #1, #2, #2, #211
bulletCF:
	bulletFib 2, #1, #43, #3, #8
bulletD0:
	bulletFib 2, #0, #244, #2, #79
bulletD1:
	bulletFib 2, #1, #29, #2, #131
bulletD2:
	bulletFib 2, #1, #72, #2, #182
bulletD3:
	bulletFib 2, #1, #118, #2, #231
bulletD4:
	bulletFib 2, #1, #45, #2, #52
bulletD5:
	bulletFib 2, #1, #91, #2, #100
bulletD6:
	bulletFib 2, #1, #138, #2, #146
bulletD7:
	bulletFib 2, #1, #189, #2, #190
bulletD8:
	bulletFib 2, #1, #99, #2, #20
bulletD9:
	bulletFib 2, #1, #149, #2, #63
bulletDA:
	bulletFib 2, #1, #201, #2, #104
bulletDB:
	bulletFib 2, #1, #255, #2, #143
bulletDC:
	bulletFib 2, #1, #150, #1, #238
bulletDD:
	bulletFib 2, #1, #203, #2, #21
bulletDE:
	bulletFib 2, #2, #3, #2, #57
bulletDF:
	bulletFib 2, #2, #61, #2, #90
bulletE0:
	bulletFib 2, #1, #196, #1, #196
bulletE1:
	bulletFib 2, #1, #253, #1, #229
bulletE2:
	bulletFib 2, #2, #57, #2, #3
bulletE3:
	bulletFib 2, #2, #117, #2, #31
bulletE4:
	bulletFib 2, #1, #238, #1, #150
bulletE5:
	bulletFib 2, #2, #42, #1, #177
bulletE6:
	bulletFib 2, #2, #104, #1, #201
bulletE7:
	bulletFib 2, #2, #168, #1, #223
bulletE8:
	bulletFib 2, #2, #20, #1, #99
bulletE9:
	bulletFib 2, #2, #82, #1, #120
bulletEA:
	bulletFib 2, #2, #146, #1, #138
bulletEB:
	bulletFib 2, #2, #211, #1, #154
bulletEC:
	bulletFib 2, #2, #52, #1, #45
bulletED:
	bulletFib 2, #2, #116, #1, #60
bulletEE:
	bulletFib 2, #2, #182, #1, #72
bulletEF:
	bulletFib 2, #2, #248, #1, #81
bulletF0:
	bulletFib 2, #2, #79, #0, #244
bulletF1:
	bulletFib 2, #2, #144, #0, #253
bulletF2:
	bulletFib 2, #2, #211, #1, #2
bulletF3:
	bulletFib 2, #3, #22, #1, #4
bulletF4:
	bulletFib 2, #2, #100, #0, #185
bulletF5:
	bulletFib 2, #2, #166, #0, #187
bulletF6:
	bulletFib 2, #2, #232, #0, #186
bulletF7:
	bulletFib 2, #3, #43, #0, #182
bulletF8:
	bulletFib 2, #2, #115, #0, #124
bulletF9:
	bulletFib 2, #2, #181, #0, #120
bulletFA:
	bulletFib 2, #2, #247, #0, #112
bulletFB:
	bulletFib 2, #3, #57, #0, #101
bulletFC:
	bulletFib 2, #2, #124, #0, #62
bulletFD:
	bulletFib 2, #2, #190, #0, #51
bulletFE:
	bulletFib 2, #2, #255, #0, #37
bulletFF:
	bulletFib 2, #3, #63, #0, #20


Bullets_move_H:
	.byte >(bullet00)
	.byte >(bullet01)
	.byte >(bullet02)
	.byte >(bullet03)
	.byte >(bullet04)
	.byte >(bullet05)
	.byte >(bullet06)
	.byte >(bullet07)
	.byte >(bullet08)
	.byte >(bullet09)
	.byte >(bullet0A)
	.byte >(bullet0B)
	.byte >(bullet0C)
	.byte >(bullet0D)
	.byte >(bullet0E)
	.byte >(bullet0F)
	.byte >(bullet10)
	.byte >(bullet11)
	.byte >(bullet12)
	.byte >(bullet13)
	.byte >(bullet14)
	.byte >(bullet15)
	.byte >(bullet16)
	.byte >(bullet17)
	.byte >(bullet18)
	.byte >(bullet19)
	.byte >(bullet1A)
	.byte >(bullet1B)
	.byte >(bullet1C)
	.byte >(bullet1D)
	.byte >(bullet1E)
	.byte >(bullet1F)
	.byte >(bullet20)
	.byte >(bullet21)
	.byte >(bullet22)
	.byte >(bullet23)
	.byte >(bullet24)
	.byte >(bullet25)
	.byte >(bullet26)
	.byte >(bullet27)
	.byte >(bullet28)
	.byte >(bullet29)
	.byte >(bullet2A)
	.byte >(bullet2B)
	.byte >(bullet2C)
	.byte >(bullet2D)
	.byte >(bullet2E)
	.byte >(bullet2F)
	.byte >(bullet30)
	.byte >(bullet31)
	.byte >(bullet32)
	.byte >(bullet33)
	.byte >(bullet34)
	.byte >(bullet35)
	.byte >(bullet36)
	.byte >(bullet37)
	.byte >(bullet38)
	.byte >(bullet39)
	.byte >(bullet3A)
	.byte >(bullet3B)
	.byte >(bullet3C)
	.byte >(bullet3D)
	.byte >(bullet3E)
	.byte >(bullet3F)
	.byte >(bullet40)
	.byte >(bullet41)
	.byte >(bullet42)
	.byte >(bullet43)
	.byte >(bullet44)
	.byte >(bullet45)
	.byte >(bullet46)
	.byte >(bullet47)
	.byte >(bullet48)
	.byte >(bullet49)
	.byte >(bullet4A)
	.byte >(bullet4B)
	.byte >(bullet4C)
	.byte >(bullet4D)
	.byte >(bullet4E)
	.byte >(bullet4F)
	.byte >(bullet50)
	.byte >(bullet51)
	.byte >(bullet52)
	.byte >(bullet53)
	.byte >(bullet54)
	.byte >(bullet55)
	.byte >(bullet56)
	.byte >(bullet57)
	.byte >(bullet58)
	.byte >(bullet59)
	.byte >(bullet5A)
	.byte >(bullet5B)
	.byte >(bullet5C)
	.byte >(bullet5D)
	.byte >(bullet5E)
	.byte >(bullet5F)
	.byte >(bullet60)
	.byte >(bullet61)
	.byte >(bullet62)
	.byte >(bullet63)
	.byte >(bullet64)
	.byte >(bullet65)
	.byte >(bullet66)
	.byte >(bullet67)
	.byte >(bullet68)
	.byte >(bullet69)
	.byte >(bullet6A)
	.byte >(bullet6B)
	.byte >(bullet6C)
	.byte >(bullet6D)
	.byte >(bullet6E)
	.byte >(bullet6F)
	.byte >(bullet70)
	.byte >(bullet71)
	.byte >(bullet72)
	.byte >(bullet73)
	.byte >(bullet74)
	.byte >(bullet75)
	.byte >(bullet76)
	.byte >(bullet77)
	.byte >(bullet78)
	.byte >(bullet79)
	.byte >(bullet7A)
	.byte >(bullet7B)
	.byte >(bullet7C)
	.byte >(bullet7D)
	.byte >(bullet7E)
	.byte >(bullet7F)
	.byte >(bullet80)
	.byte >(bullet81)
	.byte >(bullet82)
	.byte >(bullet83)
	.byte >(bullet84)
	.byte >(bullet85)
	.byte >(bullet86)
	.byte >(bullet87)
	.byte >(bullet88)
	.byte >(bullet89)
	.byte >(bullet8A)
	.byte >(bullet8B)
	.byte >(bullet8C)
	.byte >(bullet8D)
	.byte >(bullet8E)
	.byte >(bullet8F)
	.byte >(bullet90)
	.byte >(bullet91)
	.byte >(bullet92)
	.byte >(bullet93)
	.byte >(bullet94)
	.byte >(bullet95)
	.byte >(bullet96)
	.byte >(bullet97)
	.byte >(bullet98)
	.byte >(bullet99)
	.byte >(bullet9A)
	.byte >(bullet9B)
	.byte >(bullet9C)
	.byte >(bullet9D)
	.byte >(bullet9E)
	.byte >(bullet9F)
	.byte >(bulletA0)
	.byte >(bulletA1)
	.byte >(bulletA2)
	.byte >(bulletA3)
	.byte >(bulletA4)
	.byte >(bulletA5)
	.byte >(bulletA6)
	.byte >(bulletA7)
	.byte >(bulletA8)
	.byte >(bulletA9)
	.byte >(bulletAA)
	.byte >(bulletAB)
	.byte >(bulletAC)
	.byte >(bulletAD)
	.byte >(bulletAE)
	.byte >(bulletAF)
	.byte >(bulletB0)
	.byte >(bulletB1)
	.byte >(bulletB2)
	.byte >(bulletB3)
	.byte >(bulletB4)
	.byte >(bulletB5)
	.byte >(bulletB6)
	.byte >(bulletB7)
	.byte >(bulletB8)
	.byte >(bulletB9)
	.byte >(bulletBA)
	.byte >(bulletBB)
	.byte >(bulletBC)
	.byte >(bulletBD)
	.byte >(bulletBE)
	.byte >(bulletBF)
	.byte >(bulletC0)
	.byte >(bulletC1)
	.byte >(bulletC2)
	.byte >(bulletC3)
	.byte >(bulletC4)
	.byte >(bulletC5)
	.byte >(bulletC6)
	.byte >(bulletC7)
	.byte >(bulletC8)
	.byte >(bulletC9)
	.byte >(bulletCA)
	.byte >(bulletCB)
	.byte >(bulletCC)
	.byte >(bulletCD)
	.byte >(bulletCE)
	.byte >(bulletCF)
	.byte >(bulletD0)
	.byte >(bulletD1)
	.byte >(bulletD2)
	.byte >(bulletD3)
	.byte >(bulletD4)
	.byte >(bulletD5)
	.byte >(bulletD6)
	.byte >(bulletD7)
	.byte >(bulletD8)
	.byte >(bulletD9)
	.byte >(bulletDA)
	.byte >(bulletDB)
	.byte >(bulletDC)
	.byte >(bulletDD)
	.byte >(bulletDE)
	.byte >(bulletDF)
	.byte >(bulletE0)
	.byte >(bulletE1)
	.byte >(bulletE2)
	.byte >(bulletE3)
	.byte >(bulletE4)
	.byte >(bulletE5)
	.byte >(bulletE6)
	.byte >(bulletE7)
	.byte >(bulletE8)
	.byte >(bulletE9)
	.byte >(bulletEA)
	.byte >(bulletEB)
	.byte >(bulletEC)
	.byte >(bulletED)
	.byte >(bulletEE)
	.byte >(bulletEF)
	.byte >(bulletF0)
	.byte >(bulletF1)
	.byte >(bulletF2)
	.byte >(bulletF3)
	.byte >(bulletF4)
	.byte >(bulletF5)
	.byte >(bulletF6)
	.byte >(bulletF7)
	.byte >(bulletF8)
	.byte >(bulletF9)
	.byte >(bulletFA)
	.byte >(bulletFB)
	.byte >(bulletFC)
	.byte >(bulletFD)
	.byte >(bulletFE)
	.byte >(bulletFF)

Bullets_move_L:
	.byte <(bullet00)
	.byte <(bullet01)
	.byte <(bullet02)
	.byte <(bullet03)
	.byte <(bullet04)
	.byte <(bullet05)
	.byte <(bullet06)
	.byte <(bullet07)
	.byte <(bullet08)
	.byte <(bullet09)
	.byte <(bullet0A)
	.byte <(bullet0B)
	.byte <(bullet0C)
	.byte <(bullet0D)
	.byte <(bullet0E)
	.byte <(bullet0F)
	.byte <(bullet10)
	.byte <(bullet11)
	.byte <(bullet12)
	.byte <(bullet13)
	.byte <(bullet14)
	.byte <(bullet15)
	.byte <(bullet16)
	.byte <(bullet17)
	.byte <(bullet18)
	.byte <(bullet19)
	.byte <(bullet1A)
	.byte <(bullet1B)
	.byte <(bullet1C)
	.byte <(bullet1D)
	.byte <(bullet1E)
	.byte <(bullet1F)
	.byte <(bullet20)
	.byte <(bullet21)
	.byte <(bullet22)
	.byte <(bullet23)
	.byte <(bullet24)
	.byte <(bullet25)
	.byte <(bullet26)
	.byte <(bullet27)
	.byte <(bullet28)
	.byte <(bullet29)
	.byte <(bullet2A)
	.byte <(bullet2B)
	.byte <(bullet2C)
	.byte <(bullet2D)
	.byte <(bullet2E)
	.byte <(bullet2F)
	.byte <(bullet30)
	.byte <(bullet31)
	.byte <(bullet32)
	.byte <(bullet33)
	.byte <(bullet34)
	.byte <(bullet35)
	.byte <(bullet36)
	.byte <(bullet37)
	.byte <(bullet38)
	.byte <(bullet39)
	.byte <(bullet3A)
	.byte <(bullet3B)
	.byte <(bullet3C)
	.byte <(bullet3D)
	.byte <(bullet3E)
	.byte <(bullet3F)
	.byte <(bullet40)
	.byte <(bullet41)
	.byte <(bullet42)
	.byte <(bullet43)
	.byte <(bullet44)
	.byte <(bullet45)
	.byte <(bullet46)
	.byte <(bullet47)
	.byte <(bullet48)
	.byte <(bullet49)
	.byte <(bullet4A)
	.byte <(bullet4B)
	.byte <(bullet4C)
	.byte <(bullet4D)
	.byte <(bullet4E)
	.byte <(bullet4F)
	.byte <(bullet50)
	.byte <(bullet51)
	.byte <(bullet52)
	.byte <(bullet53)
	.byte <(bullet54)
	.byte <(bullet55)
	.byte <(bullet56)
	.byte <(bullet57)
	.byte <(bullet58)
	.byte <(bullet59)
	.byte <(bullet5A)
	.byte <(bullet5B)
	.byte <(bullet5C)
	.byte <(bullet5D)
	.byte <(bullet5E)
	.byte <(bullet5F)
	.byte <(bullet60)
	.byte <(bullet61)
	.byte <(bullet62)
	.byte <(bullet63)
	.byte <(bullet64)
	.byte <(bullet65)
	.byte <(bullet66)
	.byte <(bullet67)
	.byte <(bullet68)
	.byte <(bullet69)
	.byte <(bullet6A)
	.byte <(bullet6B)
	.byte <(bullet6C)
	.byte <(bullet6D)
	.byte <(bullet6E)
	.byte <(bullet6F)
	.byte <(bullet70)
	.byte <(bullet71)
	.byte <(bullet72)
	.byte <(bullet73)
	.byte <(bullet74)
	.byte <(bullet75)
	.byte <(bullet76)
	.byte <(bullet77)
	.byte <(bullet78)
	.byte <(bullet79)
	.byte <(bullet7A)
	.byte <(bullet7B)
	.byte <(bullet7C)
	.byte <(bullet7D)
	.byte <(bullet7E)
	.byte <(bullet7F)
	.byte <(bullet80)
	.byte <(bullet81)
	.byte <(bullet82)
	.byte <(bullet83)
	.byte <(bullet84)
	.byte <(bullet85)
	.byte <(bullet86)
	.byte <(bullet87)
	.byte <(bullet88)
	.byte <(bullet89)
	.byte <(bullet8A)
	.byte <(bullet8B)
	.byte <(bullet8C)
	.byte <(bullet8D)
	.byte <(bullet8E)
	.byte <(bullet8F)
	.byte <(bullet90)
	.byte <(bullet91)
	.byte <(bullet92)
	.byte <(bullet93)
	.byte <(bullet94)
	.byte <(bullet95)
	.byte <(bullet96)
	.byte <(bullet97)
	.byte <(bullet98)
	.byte <(bullet99)
	.byte <(bullet9A)
	.byte <(bullet9B)
	.byte <(bullet9C)
	.byte <(bullet9D)
	.byte <(bullet9E)
	.byte <(bullet9F)
	.byte <(bulletA0)
	.byte <(bulletA1)
	.byte <(bulletA2)
	.byte <(bulletA3)
	.byte <(bulletA4)
	.byte <(bulletA5)
	.byte <(bulletA6)
	.byte <(bulletA7)
	.byte <(bulletA8)
	.byte <(bulletA9)
	.byte <(bulletAA)
	.byte <(bulletAB)
	.byte <(bulletAC)
	.byte <(bulletAD)
	.byte <(bulletAE)
	.byte <(bulletAF)
	.byte <(bulletB0)
	.byte <(bulletB1)
	.byte <(bulletB2)
	.byte <(bulletB3)
	.byte <(bulletB4)
	.byte <(bulletB5)
	.byte <(bulletB6)
	.byte <(bulletB7)
	.byte <(bulletB8)
	.byte <(bulletB9)
	.byte <(bulletBA)
	.byte <(bulletBB)
	.byte <(bulletBC)
	.byte <(bulletBD)
	.byte <(bulletBE)
	.byte <(bulletBF)
	.byte <(bulletC0)
	.byte <(bulletC1)
	.byte <(bulletC2)
	.byte <(bulletC3)
	.byte <(bulletC4)
	.byte <(bulletC5)
	.byte <(bulletC6)
	.byte <(bulletC7)
	.byte <(bulletC8)
	.byte <(bulletC9)
	.byte <(bulletCA)
	.byte <(bulletCB)
	.byte <(bulletCC)
	.byte <(bulletCD)
	.byte <(bulletCE)
	.byte <(bulletCF)
	.byte <(bulletD0)
	.byte <(bulletD1)
	.byte <(bulletD2)
	.byte <(bulletD3)
	.byte <(bulletD4)
	.byte <(bulletD5)
	.byte <(bulletD6)
	.byte <(bulletD7)
	.byte <(bulletD8)
	.byte <(bulletD9)
	.byte <(bulletDA)
	.byte <(bulletDB)
	.byte <(bulletDC)
	.byte <(bulletDD)
	.byte <(bulletDE)
	.byte <(bulletDF)
	.byte <(bulletE0)
	.byte <(bulletE1)
	.byte <(bulletE2)
	.byte <(bulletE3)
	.byte <(bulletE4)
	.byte <(bulletE5)
	.byte <(bulletE6)
	.byte <(bulletE7)
	.byte <(bulletE8)
	.byte <(bulletE9)
	.byte <(bulletEA)
	.byte <(bulletEB)
	.byte <(bulletEC)
	.byte <(bulletED)
	.byte <(bulletEE)
	.byte <(bulletEF)
	.byte <(bulletF0)
	.byte <(bulletF1)
	.byte <(bulletF2)
	.byte <(bulletF3)
	.byte <(bulletF4)
	.byte <(bulletF5)
	.byte <(bulletF6)
	.byte <(bulletF7)
	.byte <(bulletF8)
	.byte <(bulletF9)
	.byte <(bulletFA)
	.byte <(bulletFB)
	.byte <(bulletFC)
	.byte <(bulletFD)
	.byte <(bulletFE)
	.byte <(bulletFF)

octant_adjust:
	.byte %11000000		;; x+,y-,|x|>|y|
	.byte %11111111		;; x+,y-,|x|<|y|
	.byte %00111111		;; x+,y+,|x|>|y|
	.byte %00000000		;; x+,y+,|x|<|y|
	.byte %10111111		;; x-,y-,|x|>|y|
	.byte %10000000		;; x-,y-,|x|<|y|
	.byte %01000000		;; x-,y+,|x|>|y|
	.byte %01111111		;; x-,y+,|x|<|y|

;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;
atan_tab:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $03,$03,$03,$03,$03,$03,$03,$03
	.byte $03,$03,$03,$03,$03,$04,$04,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $05,$05,$05,$05,$05,$05,$05,$05
	.byte $06,$06,$06,$06,$06,$06,$06,$06
	.byte $07,$07,$07,$07,$07,$07,$08,$08
	.byte $08,$08,$08,$08,$09,$09,$09,$09
	.byte $09,$0a,$0a,$0a,$0a,$0b,$0b,$0b
	.byte $0b,$0c,$0c,$0c,$0c,$0d,$0d,$0d
	.byte $0d,$0e,$0e,$0e,$0e,$0f,$0f,$0f
	.byte $10,$10,$10,$11,$11,$11,$12,$12
	.byte $12,$13,$13,$13,$14,$14,$15,$15
	.byte $15,$16,$16,$17,$17,$17,$18,$18
	.byte $19,$19,$19,$1a,$1a,$1b,$1b,$1c
	.byte $1c,$1c,$1d,$1d,$1e,$1e,$1f,$1f

;;;;;;;; log2(x)*32 ;;;;;;;;
log2_tab:	
	.byte $00,$00,$20,$32,$40,$4a,$52,$59
	.byte $60,$65,$6a,$6e,$72,$76,$79,$7d
	.byte $80,$82,$85,$87,$8a,$8c,$8e,$90
	.byte $92,$94,$96,$98,$99,$9b,$9d,$9e
	.byte $a0,$a1,$a2,$a4,$a5,$a6,$a7,$a9
	.byte $aa,$ab,$ac,$ad,$ae,$af,$b0,$b1
	.byte $b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9
	.byte $b9,$ba,$bb,$bc,$bd,$bd,$be,$bf
	.byte $c0,$c0,$c1,$c2,$c2,$c3,$c4,$c4
	.byte $c5,$c6,$c6,$c7,$c7,$c8,$c9,$c9
	.byte $ca,$ca,$cb,$cc,$cc,$cd,$cd,$ce
	.byte $ce,$cf,$cf,$d0,$d0,$d1,$d1,$d2
	.byte $d2,$d3,$d3,$d4,$d4,$d5,$d5,$d5
	.byte $d6,$d6,$d7,$d7,$d8,$d8,$d9,$d9
	.byte $d9,$da,$da,$db,$db,$db,$dc,$dc
	.byte $dd,$dd,$dd,$de,$de,$de,$df,$df
	.byte $df,$e0,$e0,$e1,$e1,$e1,$e2,$e2
	.byte $e2,$e3,$e3,$e3,$e4,$e4,$e4,$e5
	.byte $e5,$e5,$e6,$e6,$e6,$e7,$e7,$e7
	.byte $e7,$e8,$e8,$e8,$e9,$e9,$e9,$ea
	.byte $ea,$ea,$ea,$eb,$eb,$eb,$ec,$ec
	.byte $ec,$ec,$ed,$ed,$ed,$ed,$ee,$ee
	.byte $ee,$ee,$ef,$ef,$ef,$ef,$f0,$f0
	.byte $f0,$f1,$f1,$f1,$f1,$f1,$f2,$f2
	.byte $f2,$f2,$f3,$f3,$f3,$f3,$f4,$f4
	.byte $f4,$f4,$f5,$f5,$f5,$f5,$f5,$f6
	.byte $f6,$f6,$f6,$f7,$f7,$f7,$f7,$f7
	.byte $f8,$f8,$f8,$f8,$f9,$f9,$f9,$f9
	.byte $f9,$fa,$fa,$fa,$fa,$fa,$fb,$fb
	.byte $fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc
	.byte $fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
	.byte $fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff


Charm_speed_L:
	.byte   0,  54, 107, 159, 210,   3,  51,  97, 142, 186, 229,  15,  56,  95, 134, 171
	.byte 208, 243,  22,  55,  88, 120, 151, 181, 210, 239,  11,  38,  64,  90, 115, 139
	.byte 162, 185, 208, 230, 251,  15,  36,  55,  74,  93, 111, 128, 145, 162, 178, 194
	.byte 209, 224, 239, 253,  10,  24,  37,  50,  62,  74,  86,  97, 108, 119, 129, 140
	.byte 149, 159, 169, 178, 187, 195, 204, 212, 220, 228, 235, 243, 250,   1,   8,  14
	.byte  21,  27,  33,  39,  45,  50,  56,  61,  66,  72,  76,  81,  86,  90,  95,  99
	.byte 103, 107, 111, 115, 119, 123, 126, 130, 133, 136, 139, 142, 146, 148, 151, 154
	.byte 157, 159, 162, 164, 167, 169, 172, 174, 176, 178, 180, 182, 184, 186, 188, 190
	.byte 192, 193, 195, 196, 198, 200, 201, 203, 204, 205, 207, 208, 209, 210, 212, 213
	.byte 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 226, 227, 228
	.byte 229, 229, 230, 231, 231, 232, 233, 233, 234, 234, 235, 236, 236, 237, 237, 238
	.byte 238, 239, 239, 239, 240, 240, 241, 241, 241, 242, 242, 243, 243, 243, 244, 244
	.byte 244, 244, 245, 245, 245, 246, 246, 246, 246, 247, 247, 247, 247, 248, 248, 248
	.byte 248, 248, 249, 249, 249, 249, 249, 249, 250, 250, 250, 250, 250, 250, 250, 251
	.byte 251, 251, 251, 251, 251, 251, 251, 252, 252, 252, 252, 252, 252, 252, 252, 252
	.byte 252, 252, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253
Charm_speed_H:
	.byte   0,   0,   0,   0,   0,   1,   1,   1,   1,   1,   1,   2,   2,   2,   2,   2
	.byte   2,   2,   3,   3,   3,   3,   3,   3,   3,   3,   4,   4,   4,   4,   4,   4
	.byte   4,   4,   4,   4,   4,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5
	.byte   5,   5,   5,   5,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6
	.byte   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   6,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
	.byte   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
