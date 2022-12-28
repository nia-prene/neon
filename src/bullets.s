.include "bullets.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "bombs.h"
.include "enemies.h"

BULLETS_VARIETIES=8
MAX_ENEMY_BULLETS=80

.zeropage
;arguments


;locals
getAt:.res 1
octant: .res 1
bulletAngle: .res 1
Charms_active: .res 1
quickBulletX: .res 1
quickBulletY: .res 1

isEnemyBulletActive: .res MAX_ENEMY_BULLETS

.data
Bullet_invisibility:	.res 1;		invisibility for constructed bullet
Bullet_type:		.res 1;		type for cunstructed bullet

Bullets_ID: 		.res MAX_ENEMY_BULLETS
Bullets_type:		.res MAX_ENEMY_BULLETS
enemyBulletXH:		.res MAX_ENEMY_BULLETS
enemyBulletXL:		.res MAX_ENEMY_BULLETS
enemyBulletYH:		.res MAX_ENEMY_BULLETS
enemyBulletYL:		.res MAX_ENEMY_BULLETS


.code

	
Bullets_new:; c(x) | x
	
	pha; save ID
	jsr Bullets_get;c,y(void) | x
	pla; restore ID
	bcc @bulletsFull;returns clear if full
		sta Bullets_ID,y
		
		lda enemyXH,x; coordinate copy
		sta enemyBulletXH,y
		lda enemyYH,x
		sta enemyBulletYH,y;
		
		lda Bullet_type
		sta Bullets_type,y
	
		lda Bullet_invisibility; invisibility frames
		sta isEnemyBulletActive,y
	
@bulletsFull:
	rts; c

.align 16
Bullets_get:; c,y() | x
;returns x - active offset
;returns carry clear if full
	
	ldy getAt
@bulletLoop:
	lda isEnemyBulletActive,y
	beq @return
		dey
		bpl @bulletLoop
		clc;mark full
		iny
		sty getAt
		rts
@return:
	sec ;mark success
	sty getAt
	rts

.align 32
Bullets_tick:; void()

	ldx #MAX_ENEMY_BULLETS-1; for each bullet
	stx getAt

Bullets_moveLoop:
	lda isEnemyBulletActive,x
	beq Bullets_tickDown;skip inactive bullets
		
		cmp #1
		beq :+
			;sec
			sbc #1
			sta isEnemyBulletActive,x
		:
		ldy Bullets_ID,x

		lda Bullets_move_L,y
		sta Lib_ptr0+0
		lda Bullets_move_H,y
		sta Lib_ptr0+1

		jmp (Lib_ptr0); void (a) | x
		
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
		
		cmp #1;			if invisible
		beq :+
			lda #FALSE; 		clear invisible bullets
			sta isEnemyBulletActive,x
			jmp @skipCharm;		next charm
		:;			else
		clc; 			make the bullet fall down
		lda enemyBulletYH,x
		adc #1
		bcc :+
			lda #255;	no overflow
		:sta enemyBulletYH,x
		
		lda #BULLET04;		change type
		sta Bullets_type,x

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
		
		cmp #1
		beq :+
			lda #FALSE
			sta isEnemyBulletActive,x
			jmp @nextCharm
		:
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

	rts


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

BULLET01 = $01;		standard, color 11
BULLET02 = $02;		standard, color 01
BULLET03 = $03;		standard, color 10
BULLET04 = $04;		standard, color 01


Bullets_sprite:
	.byte NULL,SPRITE28,SPRITE29,SPRITE2A
	.byte SPRITE1E

Bullets_dangerDistance:

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
	bulletFib 3, #1, #0, #0, #0
bullet01:
	bulletFib 3, #1, #63, #0, #7
bullet02:
	bulletFib 3, #1, #127, #0, #18
bullet03:
	bulletFib 3, #1, #190, #0, #32
bullet04:
	bulletFib 3, #0, #254, #0, #25
bullet05:
	bulletFib 3, #1, #61, #0, #39
bullet06:
	bulletFib 3, #1, #123, #0, #56
bullet07:
	bulletFib 3, #1, #185, #0, #76
bullet08:
	bulletFib 3, #0, #251, #0, #49
bullet09:
	bulletFib 3, #1, #56, #0, #70
bullet0A:
	bulletFib 3, #1, #116, #0, #93
bullet0B:
	bulletFib 3, #1, #175, #0, #119
bullet0C:
	bulletFib 3, #0, #244, #0, #74
bullet0D:
	bulletFib 3, #1, #47, #0, #100
bullet0E:
	bulletFib 3, #1, #105, #0, #129
bullet0F:
	bulletFib 3, #1, #161, #0, #161
bullet10:
	bulletFib 3, #0, #236, #0, #97
bullet11:
	bulletFib 3, #1, #36, #0, #129
bullet12:
	bulletFib 3, #1, #91, #0, #164
bullet13:
	bulletFib 3, #1, #144, #0, #201
bullet14:
	bulletFib 3, #0, #225, #0, #120
bullet15:
	bulletFib 3, #1, #22, #0, #157
bullet16:
	bulletFib 3, #1, #73, #0, #197
bullet17:
	bulletFib 3, #1, #122, #0, #239
bullet18:
	bulletFib 3, #0, #212, #0, #142
bullet19:
	bulletFib 3, #1, #5, #0, #184
bullet1A:
	bulletFib 3, #1, #52, #0, #228
bullet1B:
	bulletFib 3, #1, #97, #1, #19
bullet1C:
	bulletFib 3, #0, #197, #0, #162
bullet1D:
	bulletFib 3, #0, #242, #0, #209
bullet1E:
	bulletFib 3, #1, #28, #1, #1
bullet1F:
	bulletFib 3, #1, #68, #1, #52
bullet20:
	bulletFib 3, #0, #181, #0, #181
bullet21:
	bulletFib 3, #0, #220, #0, #231
bullet22:
	bulletFib 3, #1, #1, #1, #28
bullet23:
	bulletFib 3, #1, #36, #1, #83
bullet24:
	bulletFib 3, #0, #162, #0, #197
bullet25:
	bulletFib 3, #0, #196, #0, #252
bullet26:
	bulletFib 3, #0, #228, #1, #52
bullet27:
	bulletFib 3, #1, #1, #1, #110
bullet28:
	bulletFib 3, #0, #142, #0, #212
bullet29:
	bulletFib 3, #0, #171, #1, #14
bullet2A:
	bulletFib 3, #0, #197, #1, #73
bullet2B:
	bulletFib 3, #0, #220, #1, #133
bullet2C:
	bulletFib 3, #0, #120, #0, #225
bullet2D:
	bulletFib 3, #0, #143, #1, #29
bullet2E:
	bulletFib 3, #0, #164, #1, #91
bullet2F:
	bulletFib 3, #0, #181, #1, #153
bullet30:
	bulletFib 3, #0, #97, #0, #236
bullet31:
	bulletFib 3, #0, #115, #1, #42
bullet32:
	bulletFib 3, #0, #129, #1, #105
bullet33:
	bulletFib 3, #0, #140, #1, #169
bullet34:
	bulletFib 3, #0, #74, #0, #244
bullet35:
	bulletFib 3, #0, #85, #1, #52
bullet36:
	bulletFib 3, #0, #93, #1, #116
bullet37:
	bulletFib 3, #0, #98, #1, #181
bullet38:
	bulletFib 3, #0, #49, #0, #251
bullet39:
	bulletFib 3, #0, #54, #1, #59
bullet3A:
	bulletFib 3, #0, #56, #1, #123
bullet3B:
	bulletFib 3, #0, #54, #1, #188
bullet3C:
	bulletFib 3, #0, #25, #0, #254
bullet3D:
	bulletFib 3, #0, #23, #1, #63
bullet3E:
	bulletFib 3, #0, #18, #1, #127
bullet3F:
	bulletFib 3, #0, #10, #1, #191
bullet40:
	bulletFib 4, #0, #0, #1, #0
bullet41:
	bulletFib 4, #0, #7, #1, #63
bullet42:
	bulletFib 4, #0, #18, #1, #127
bullet43:
	bulletFib 4, #0, #32, #1, #190
bullet44:
	bulletFib 4, #0, #25, #0, #254
bullet45:
	bulletFib 4, #0, #39, #1, #61
bullet46:
	bulletFib 4, #0, #56, #1, #123
bullet47:
	bulletFib 4, #0, #76, #1, #185
bullet48:
	bulletFib 4, #0, #49, #0, #251
bullet49:
	bulletFib 4, #0, #70, #1, #56
bullet4A:
	bulletFib 4, #0, #93, #1, #116
bullet4B:
	bulletFib 4, #0, #119, #1, #175
bullet4C:
	bulletFib 4, #0, #74, #0, #244
bullet4D:
	bulletFib 4, #0, #100, #1, #47
bullet4E:
	bulletFib 4, #0, #129, #1, #105
bullet4F:
	bulletFib 4, #0, #161, #1, #161
bullet50:
	bulletFib 4, #0, #97, #0, #236
bullet51:
	bulletFib 4, #0, #129, #1, #36
bullet52:
	bulletFib 4, #0, #164, #1, #91
bullet53:
	bulletFib 4, #0, #201, #1, #144
bullet54:
	bulletFib 4, #0, #120, #0, #225
bullet55:
	bulletFib 4, #0, #157, #1, #22
bullet56:
	bulletFib 4, #0, #197, #1, #73
bullet57:
	bulletFib 4, #0, #239, #1, #122
bullet58:
	bulletFib 4, #0, #142, #0, #212
bullet59:
	bulletFib 4, #0, #184, #1, #5
bullet5A:
	bulletFib 4, #0, #228, #1, #52
bullet5B:
	bulletFib 4, #1, #19, #1, #97
bullet5C:
	bulletFib 4, #0, #162, #0, #197
bullet5D:
	bulletFib 4, #0, #209, #0, #242
bullet5E:
	bulletFib 4, #1, #1, #1, #28
bullet5F:
	bulletFib 4, #1, #52, #1, #68
bullet60:
	bulletFib 4, #0, #181, #0, #181
bullet61:
	bulletFib 4, #0, #231, #0, #220
bullet62:
	bulletFib 4, #1, #28, #1, #1
bullet63:
	bulletFib 4, #1, #83, #1, #36
bullet64:
	bulletFib 4, #0, #197, #0, #162
bullet65:
	bulletFib 4, #0, #252, #0, #196
bullet66:
	bulletFib 4, #1, #52, #0, #228
bullet67:
	bulletFib 4, #1, #110, #1, #1
bullet68:
	bulletFib 4, #0, #212, #0, #142
bullet69:
	bulletFib 4, #1, #14, #0, #171
bullet6A:
	bulletFib 4, #1, #73, #0, #197
bullet6B:
	bulletFib 4, #1, #133, #0, #220
bullet6C:
	bulletFib 4, #0, #225, #0, #120
bullet6D:
	bulletFib 4, #1, #29, #0, #143
bullet6E:
	bulletFib 4, #1, #91, #0, #164
bullet6F:
	bulletFib 4, #1, #153, #0, #181
bullet70:
	bulletFib 4, #0, #236, #0, #97
bullet71:
	bulletFib 4, #1, #42, #0, #115
bullet72:
	bulletFib 4, #1, #105, #0, #129
bullet73:
	bulletFib 4, #1, #169, #0, #140
bullet74:
	bulletFib 4, #0, #244, #0, #74
bullet75:
	bulletFib 4, #1, #52, #0, #85
bullet76:
	bulletFib 4, #1, #116, #0, #93
bullet77:
	bulletFib 4, #1, #181, #0, #98
bullet78:
	bulletFib 4, #0, #251, #0, #49
bullet79:
	bulletFib 4, #1, #59, #0, #54
bullet7A:
	bulletFib 4, #1, #123, #0, #56
bullet7B:
	bulletFib 4, #1, #188, #0, #54
bullet7C:
	bulletFib 4, #0, #254, #0, #25
bullet7D:
	bulletFib 4, #1, #63, #0, #23
bullet7E:
	bulletFib 4, #1, #127, #0, #18
bullet7F:
	bulletFib 4, #1, #191, #0, #10
bullet80:
	bulletFib 1, #1, #0, #0, #0
bullet81:
	bulletFib 1, #1, #63, #0, #7
bullet82:
	bulletFib 1, #1, #127, #0, #18
bullet83:
	bulletFib 1, #1, #190, #0, #32
bullet84:
	bulletFib 1, #0, #254, #0, #25
bullet85:
	bulletFib 1, #1, #61, #0, #39
bullet86:
	bulletFib 1, #1, #123, #0, #56
bullet87:
	bulletFib 1, #1, #185, #0, #76
bullet88:
	bulletFib 1, #0, #251, #0, #49
bullet89:
	bulletFib 1, #1, #56, #0, #70
bullet8A:
	bulletFib 1, #1, #116, #0, #93
bullet8B:
	bulletFib 1, #1, #175, #0, #119
bullet8C:
	bulletFib 1, #0, #244, #0, #74
bullet8D:
	bulletFib 1, #1, #47, #0, #100
bullet8E:
	bulletFib 1, #1, #105, #0, #129
bullet8F:
	bulletFib 1, #1, #161, #0, #161
bullet90:
	bulletFib 1, #0, #236, #0, #97
bullet91:
	bulletFib 1, #1, #36, #0, #129
bullet92:
	bulletFib 1, #1, #91, #0, #164
bullet93:
	bulletFib 1, #1, #144, #0, #201
bullet94:
	bulletFib 1, #0, #225, #0, #120
bullet95:
	bulletFib 1, #1, #22, #0, #157
bullet96:
	bulletFib 1, #1, #73, #0, #197
bullet97:
	bulletFib 1, #1, #122, #0, #239
bullet98:
	bulletFib 1, #0, #212, #0, #142
bullet99:
	bulletFib 1, #1, #5, #0, #184
bullet9A:
	bulletFib 1, #1, #52, #0, #228
bullet9B:
	bulletFib 1, #1, #97, #1, #19
bullet9C:
	bulletFib 1, #0, #197, #0, #162
bullet9D:
	bulletFib 1, #0, #242, #0, #209
bullet9E:
	bulletFib 1, #1, #28, #1, #1
bullet9F:
	bulletFib 1, #1, #68, #1, #52
bulletA0:
	bulletFib 1, #0, #181, #0, #181
bulletA1:
	bulletFib 1, #0, #220, #0, #231
bulletA2:
	bulletFib 1, #1, #1, #1, #28
bulletA3:
	bulletFib 1, #1, #36, #1, #83
bulletA4:
	bulletFib 1, #0, #162, #0, #197
bulletA5:
	bulletFib 1, #0, #196, #0, #252
bulletA6:
	bulletFib 1, #0, #228, #1, #52
bulletA7:
	bulletFib 1, #1, #1, #1, #110
bulletA8:
	bulletFib 1, #0, #142, #0, #212
bulletA9:
	bulletFib 1, #0, #171, #1, #14
bulletAA:
	bulletFib 1, #0, #197, #1, #73
bulletAB:
	bulletFib 1, #0, #220, #1, #133
bulletAC:
	bulletFib 1, #0, #120, #0, #225
bulletAD:
	bulletFib 1, #0, #143, #1, #29
bulletAE:
	bulletFib 1, #0, #164, #1, #91
bulletAF:
	bulletFib 1, #0, #181, #1, #153
bulletB0:
	bulletFib 1, #0, #97, #0, #236
bulletB1:
	bulletFib 1, #0, #115, #1, #42
bulletB2:
	bulletFib 1, #0, #129, #1, #105
bulletB3:
	bulletFib 1, #0, #140, #1, #169
bulletB4:
	bulletFib 1, #0, #74, #0, #244
bulletB5:
	bulletFib 1, #0, #85, #1, #52
bulletB6:
	bulletFib 1, #0, #93, #1, #116
bulletB7:
	bulletFib 1, #0, #98, #1, #181
bulletB8:
	bulletFib 1, #0, #49, #0, #251
bulletB9:
	bulletFib 1, #0, #54, #1, #59
bulletBA:
	bulletFib 1, #0, #56, #1, #123
bulletBB:
	bulletFib 1, #0, #54, #1, #188
bulletBC:
	bulletFib 1, #0, #25, #0, #254
bulletBD:
	bulletFib 1, #0, #23, #1, #63
bulletBE:
	bulletFib 1, #0, #18, #1, #127
bulletBF:
	bulletFib 1, #0, #10, #1, #191
bulletC0:
	bulletFib 2, #0, #0, #1, #0
bulletC1:
	bulletFib 2, #0, #7, #1, #63
bulletC2:
	bulletFib 2, #0, #18, #1, #127
bulletC3:
	bulletFib 2, #0, #32, #1, #190
bulletC4:
	bulletFib 2, #0, #25, #0, #254
bulletC5:
	bulletFib 2, #0, #39, #1, #61
bulletC6:
	bulletFib 2, #0, #56, #1, #123
bulletC7:
	bulletFib 2, #0, #76, #1, #185
bulletC8:
	bulletFib 2, #0, #49, #0, #251
bulletC9:
	bulletFib 2, #0, #70, #1, #56
bulletCA:
	bulletFib 2, #0, #93, #1, #116
bulletCB:
	bulletFib 2, #0, #119, #1, #175
bulletCC:
	bulletFib 2, #0, #74, #0, #244
bulletCD:
	bulletFib 2, #0, #100, #1, #47
bulletCE:
	bulletFib 2, #0, #129, #1, #105
bulletCF:
	bulletFib 2, #0, #161, #1, #161
bulletD0:
	bulletFib 2, #0, #97, #0, #236
bulletD1:
	bulletFib 2, #0, #129, #1, #36
bulletD2:
	bulletFib 2, #0, #164, #1, #91
bulletD3:
	bulletFib 2, #0, #201, #1, #144
bulletD4:
	bulletFib 2, #0, #120, #0, #225
bulletD5:
	bulletFib 2, #0, #157, #1, #22
bulletD6:
	bulletFib 2, #0, #197, #1, #73
bulletD7:
	bulletFib 2, #0, #239, #1, #122
bulletD8:
	bulletFib 2, #0, #142, #0, #212
bulletD9:
	bulletFib 2, #0, #184, #1, #5
bulletDA:
	bulletFib 2, #0, #228, #1, #52
bulletDB:
	bulletFib 2, #1, #19, #1, #97
bulletDC:
	bulletFib 2, #0, #162, #0, #197
bulletDD:
	bulletFib 2, #0, #209, #0, #242
bulletDE:
	bulletFib 2, #1, #1, #1, #28
bulletDF:
	bulletFib 2, #1, #52, #1, #68
bulletE0:
	bulletFib 2, #0, #181, #0, #181
bulletE1:
	bulletFib 2, #0, #231, #0, #220
bulletE2:
	bulletFib 2, #1, #28, #1, #1
bulletE3:
	bulletFib 2, #1, #83, #1, #36
bulletE4:
	bulletFib 2, #0, #197, #0, #162
bulletE5:
	bulletFib 2, #0, #252, #0, #196
bulletE6:
	bulletFib 2, #1, #52, #0, #228
bulletE7:
	bulletFib 2, #1, #110, #1, #1
bulletE8:
	bulletFib 2, #0, #212, #0, #142
bulletE9:
	bulletFib 2, #1, #14, #0, #171
bulletEA:
	bulletFib 2, #1, #73, #0, #197
bulletEB:
	bulletFib 2, #1, #133, #0, #220
bulletEC:
	bulletFib 2, #0, #225, #0, #120
bulletED:
	bulletFib 2, #1, #29, #0, #143
bulletEE:
	bulletFib 2, #1, #91, #0, #164
bulletEF:
	bulletFib 2, #1, #153, #0, #181
bulletF0:
	bulletFib 2, #0, #236, #0, #97
bulletF1:
	bulletFib 2, #1, #42, #0, #115
bulletF2:
	bulletFib 2, #1, #105, #0, #129
bulletF3:
	bulletFib 2, #1, #169, #0, #140
bulletF4:
	bulletFib 2, #0, #244, #0, #74
bulletF5:
	bulletFib 2, #1, #52, #0, #85
bulletF6:
	bulletFib 2, #1, #116, #0, #93
bulletF7:
	bulletFib 2, #1, #181, #0, #98
bulletF8:
	bulletFib 2, #0, #251, #0, #49
bulletF9:
	bulletFib 2, #1, #59, #0, #54
bulletFA:
	bulletFib 2, #1, #123, #0, #56
bulletFB:
	bulletFib 2, #1, #188, #0, #54
bulletFC:
	bulletFib 2, #0, #254, #0, #25
bulletFD:
	bulletFib 2, #1, #63, #0, #23
bulletFE:
	bulletFib 2, #1, #127, #0, #18
bulletFF:
	bulletFib 2, #1, #191, #0, #10

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
