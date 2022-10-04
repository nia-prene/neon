.include "bullets.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "bombs.h"
.include "enemies.h"

BULLETS_VARIETIES=8
MAX_ENEMY_BULLETS=129

.zeropage
;arguments
Bullets_fastForwardFrames:.res 1

;pointers
Bullets_move: .res 2

;locals
getAt:.res 1
octant: .res 1
bulletAngle: .res 1
Charms_active: .res 1
quickBulletX: .res 1
quickBulletY: .res 1

isEnemyBulletActive: .res MAX_ENEMY_BULLETS

.data

Bullets_ID: .res MAX_ENEMY_BULLETS
enemyBulletXH: .res MAX_ENEMY_BULLETS
enemyBulletXL: .res MAX_ENEMY_BULLETS
enemyBulletYH: .res MAX_ENEMY_BULLETS
enemyBulletYL: .res MAX_ENEMY_BULLETS

.code

Bullets_init:
	
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
	bulletFib 3, #1, #128, #0, #0
bullet01:
	bulletFib 3, #1, #255, #0, #12
bullet02:
	bulletFib 3, #2, #127, #0, #31
bullet03:
	bulletFib 3, #2, #253, #0, #56
bullet04:
	bulletFib 3, #1, #126, #0, #37
bullet05:
	bulletFib 3, #1, #252, #0, #62
bullet06:
	bulletFib 3, #2, #121, #0, #93
bullet07:
	bulletFib 3, #2, #244, #0, #131
bullet08:
	bulletFib 3, #1, #120, #0, #74
bullet09:
	bulletFib 3, #1, #243, #0, #112
bullet0A:
	bulletFib 3, #2, #108, #0, #155
bullet0B:
	bulletFib 3, #2, #228, #0, #204
bullet0C:
	bulletFib 3, #1, #111, #0, #111
bullet0D:
	bulletFib 3, #1, #230, #0, #160
bullet0E:
	bulletFib 3, #2, #90, #0, #215
bullet0F:
	bulletFib 3, #2, #204, #1, #20
bullet10:
	bulletFib 3, #1, #98, #0, #146
bullet11:
	bulletFib 3, #1, #212, #0, #207
bullet12:
	bulletFib 3, #2, #66, #1, #17
bullet13:
	bulletFib 3, #2, #173, #1, #89
bullet14:
	bulletFib 3, #1, #82, #0, #181
bullet15:
	bulletFib 3, #1, #189, #0, #252
bullet16:
	bulletFib 3, #2, #36, #1, #73
bullet17:
	bulletFib 3, #2, #136, #1, #154
bullet18:
	bulletFib 3, #1, #63, #0, #213
bullet19:
	bulletFib 3, #1, #162, #1, #38
bullet1A:
	bulletFib 3, #2, #2, #1, #125
bullet1B:
	bulletFib 3, #2, #93, #1, #216
bullet1C:
	bulletFib 3, #1, #40, #0, #243
bullet1D:
	bulletFib 3, #1, #131, #1, #78
bullet1E:
	bulletFib 3, #1, #218, #1, #173
bullet1F:
	bulletFib 3, #2, #44, #2, #17
bullet20:
	bulletFib 3, #1, #15, #1, #15
bullet21:
	bulletFib 3, #1, #97, #1, #114
bullet22:
	bulletFib 3, #1, #173, #1, #218
bullet23:
	bulletFib 3, #1, #245, #2, #69
bullet24:
	bulletFib 3, #0, #243, #1, #40
bullet25:
	bulletFib 3, #1, #58, #1, #147
bullet26:
	bulletFib 3, #1, #125, #2, #2
bullet27:
	bulletFib 3, #1, #186, #2, #115
bullet28:
	bulletFib 3, #0, #213, #1, #63
bullet29:
	bulletFib 3, #1, #17, #1, #176
bullet2A:
	bulletFib 3, #1, #73, #2, #36
bullet2B:
	bulletFib 3, #1, #122, #2, #156
bullet2C:
	bulletFib 3, #0, #181, #1, #82
bullet2D:
	bulletFib 3, #0, #230, #1, #201
bullet2E:
	bulletFib 3, #1, #17, #2, #66
bullet2F:
	bulletFib 3, #1, #55, #2, #190
bullet30:
	bulletFib 3, #0, #146, #1, #98
bullet31:
	bulletFib 3, #0, #184, #1, #221
bullet32:
	bulletFib 3, #0, #215, #2, #90
bullet33:
	bulletFib 3, #0, #240, #2, #217
bullet34:
	bulletFib 3, #0, #111, #1, #111
bullet35:
	bulletFib 3, #0, #136, #1, #237
bullet36:
	bulletFib 3, #0, #155, #2, #108
bullet37:
	bulletFib 3, #0, #168, #2, #237
bullet38:
	bulletFib 3, #0, #74, #1, #120
bullet39:
	bulletFib 3, #0, #87, #1, #248
bullet3A:
	bulletFib 3, #0, #93, #2, #121
bullet3B:
	bulletFib 3, #0, #94, #2, #250
bullet3C:
	bulletFib 3, #0, #37, #1, #126
bullet3D:
	bulletFib 3, #0, #37, #1, #254
bullet3E:
	bulletFib 3, #0, #31, #2, #127
bullet3F:
	bulletFib 3, #0, #18, #2, #255
bullet40:
	bulletFib 4, #0, #0, #1, #128
bullet41:
	bulletFib 4, #0, #12, #1, #255
bullet42:
	bulletFib 4, #0, #31, #2, #127
bullet43:
	bulletFib 4, #0, #56, #2, #253
bullet44:
	bulletFib 4, #0, #37, #1, #126
bullet45:
	bulletFib 4, #0, #62, #1, #252
bullet46:
	bulletFib 4, #0, #93, #2, #121
bullet47:
	bulletFib 4, #0, #131, #2, #244
bullet48:
	bulletFib 4, #0, #74, #1, #120
bullet49:
	bulletFib 4, #0, #112, #1, #243
bullet4A:
	bulletFib 4, #0, #155, #2, #108
bullet4B:
	bulletFib 4, #0, #204, #2, #228
bullet4C:
	bulletFib 4, #0, #111, #1, #111
bullet4D:
	bulletFib 4, #0, #160, #1, #230
bullet4E:
	bulletFib 4, #0, #215, #2, #90
bullet4F:
	bulletFib 4, #1, #20, #2, #204
bullet50:
	bulletFib 4, #0, #146, #1, #98
bullet51:
	bulletFib 4, #0, #207, #1, #212
bullet52:
	bulletFib 4, #1, #17, #2, #66
bullet53:
	bulletFib 4, #1, #89, #2, #173
bullet54:
	bulletFib 4, #0, #181, #1, #82
bullet55:
	bulletFib 4, #0, #252, #1, #189
bullet56:
	bulletFib 4, #1, #73, #2, #36
bullet57:
	bulletFib 4, #1, #154, #2, #136
bullet58:
	bulletFib 4, #0, #213, #1, #63
bullet59:
	bulletFib 4, #1, #38, #1, #162
bullet5A:
	bulletFib 4, #1, #125, #2, #2
bullet5B:
	bulletFib 4, #1, #216, #2, #93
bullet5C:
	bulletFib 4, #0, #243, #1, #40
bullet5D:
	bulletFib 4, #1, #78, #1, #131
bullet5E:
	bulletFib 4, #1, #173, #1, #218
bullet5F:
	bulletFib 4, #2, #17, #2, #44
bullet60:
	bulletFib 4, #1, #15, #1, #15
bullet61:
	bulletFib 4, #1, #114, #1, #97
bullet62:
	bulletFib 4, #1, #218, #1, #173
bullet63:
	bulletFib 4, #2, #69, #1, #245
bullet64:
	bulletFib 4, #1, #40, #0, #243
bullet65:
	bulletFib 4, #1, #147, #1, #58
bullet66:
	bulletFib 4, #2, #2, #1, #125
bullet67:
	bulletFib 4, #2, #115, #1, #186
bullet68:
	bulletFib 4, #1, #63, #0, #213
bullet69:
	bulletFib 4, #1, #176, #1, #17
bullet6A:
	bulletFib 4, #2, #36, #1, #73
bullet6B:
	bulletFib 4, #2, #156, #1, #122
bullet6C:
	bulletFib 4, #1, #82, #0, #181
bullet6D:
	bulletFib 4, #1, #201, #0, #230
bullet6E:
	bulletFib 4, #2, #66, #1, #17
bullet6F:
	bulletFib 4, #2, #190, #1, #55
bullet70:
	bulletFib 4, #1, #98, #0, #146
bullet71:
	bulletFib 4, #1, #221, #0, #184
bullet72:
	bulletFib 4, #2, #90, #0, #215
bullet73:
	bulletFib 4, #2, #217, #0, #240
bullet74:
	bulletFib 4, #1, #111, #0, #111
bullet75:
	bulletFib 4, #1, #237, #0, #136
bullet76:
	bulletFib 4, #2, #108, #0, #155
bullet77:
	bulletFib 4, #2, #237, #0, #168
bullet78:
	bulletFib 4, #1, #120, #0, #74
bullet79:
	bulletFib 4, #1, #248, #0, #87
bullet7A:
	bulletFib 4, #2, #121, #0, #93
bullet7B:
	bulletFib 4, #2, #250, #0, #94
bullet7C:
	bulletFib 4, #1, #126, #0, #37
bullet7D:
	bulletFib 4, #1, #254, #0, #37
bullet7E:
	bulletFib 4, #2, #127, #0, #31
bullet7F:
	bulletFib 4, #2, #255, #0, #18
bullet80:
	bulletFib 1, #1, #128, #0, #0
bullet81:
	bulletFib 1, #1, #255, #0, #12
bullet82:
	bulletFib 1, #2, #127, #0, #31
bullet83:
	bulletFib 1, #2, #253, #0, #56
bullet84:
	bulletFib 1, #1, #126, #0, #37
bullet85:
	bulletFib 1, #1, #252, #0, #62
bullet86:
	bulletFib 1, #2, #121, #0, #93
bullet87:
	bulletFib 1, #2, #244, #0, #131
bullet88:
	bulletFib 1, #1, #120, #0, #74
bullet89:
	bulletFib 1, #1, #243, #0, #112
bullet8A:
	bulletFib 1, #2, #108, #0, #155
bullet8B:
	bulletFib 1, #2, #228, #0, #204
bullet8C:
	bulletFib 1, #1, #111, #0, #111
bullet8D:
	bulletFib 1, #1, #230, #0, #160
bullet8E:
	bulletFib 1, #2, #90, #0, #215
bullet8F:
	bulletFib 1, #2, #204, #1, #20
bullet90:
	bulletFib 1, #1, #98, #0, #146
bullet91:
	bulletFib 1, #1, #212, #0, #207
bullet92:
	bulletFib 1, #2, #66, #1, #17
bullet93:
	bulletFib 1, #2, #173, #1, #89
bullet94:
	bulletFib 1, #1, #82, #0, #181
bullet95:
	bulletFib 1, #1, #189, #0, #252
bullet96:
	bulletFib 1, #2, #36, #1, #73
bullet97:
	bulletFib 1, #2, #136, #1, #154
bullet98:
	bulletFib 1, #1, #63, #0, #213
bullet99:
	bulletFib 1, #1, #162, #1, #38
bullet9A:
	bulletFib 1, #2, #2, #1, #125
bullet9B:
	bulletFib 1, #2, #93, #1, #216
bullet9C:
	bulletFib 1, #1, #40, #0, #243
bullet9D:
	bulletFib 1, #1, #131, #1, #78
bullet9E:
	bulletFib 1, #1, #218, #1, #173
bullet9F:
	bulletFib 1, #2, #44, #2, #17
bulletA0:
	bulletFib 1, #1, #15, #1, #15
bulletA1:
	bulletFib 1, #1, #97, #1, #114
bulletA2:
	bulletFib 1, #1, #173, #1, #218
bulletA3:
	bulletFib 1, #1, #245, #2, #69
bulletA4:
	bulletFib 1, #0, #243, #1, #40
bulletA5:
	bulletFib 1, #1, #58, #1, #147
bulletA6:
	bulletFib 1, #1, #125, #2, #2
bulletA7:
	bulletFib 1, #1, #186, #2, #115
bulletA8:
	bulletFib 1, #0, #213, #1, #63
bulletA9:
	bulletFib 1, #1, #17, #1, #176
bulletAA:
	bulletFib 1, #1, #73, #2, #36
bulletAB:
	bulletFib 1, #1, #122, #2, #156
bulletAC:
	bulletFib 1, #0, #181, #1, #82
bulletAD:
	bulletFib 1, #0, #230, #1, #201
bulletAE:
	bulletFib 1, #1, #17, #2, #66
bulletAF:
	bulletFib 1, #1, #55, #2, #190
bulletB0:
	bulletFib 1, #0, #146, #1, #98
bulletB1:
	bulletFib 1, #0, #184, #1, #221
bulletB2:
	bulletFib 1, #0, #215, #2, #90
bulletB3:
	bulletFib 1, #0, #240, #2, #217
bulletB4:
	bulletFib 1, #0, #111, #1, #111
bulletB5:
	bulletFib 1, #0, #136, #1, #237
bulletB6:
	bulletFib 1, #0, #155, #2, #108
bulletB7:
	bulletFib 1, #0, #168, #2, #237
bulletB8:
	bulletFib 1, #0, #74, #1, #120
bulletB9:
	bulletFib 1, #0, #87, #1, #248
bulletBA:
	bulletFib 1, #0, #93, #2, #121
bulletBB:
	bulletFib 1, #0, #94, #2, #250
bulletBC:
	bulletFib 1, #0, #37, #1, #126
bulletBD:
	bulletFib 1, #0, #37, #1, #254
bulletBE:
	bulletFib 1, #0, #31, #2, #127
bulletBF:
	bulletFib 1, #0, #18, #2, #255
bulletC0:
	bulletFib 2, #0, #0, #1, #128
bulletC1:
	bulletFib 2, #0, #12, #1, #255
bulletC2:
	bulletFib 2, #0, #31, #2, #127
bulletC3:
	bulletFib 2, #0, #56, #2, #253
bulletC4:
	bulletFib 2, #0, #37, #1, #126
bulletC5:
	bulletFib 2, #0, #62, #1, #252
bulletC6:
	bulletFib 2, #0, #93, #2, #121
bulletC7:
	bulletFib 2, #0, #131, #2, #244
bulletC8:
	bulletFib 2, #0, #74, #1, #120
bulletC9:
	bulletFib 2, #0, #112, #1, #243
bulletCA:
	bulletFib 2, #0, #155, #2, #108
bulletCB:
	bulletFib 2, #0, #204, #2, #228
bulletCC:
	bulletFib 2, #0, #111, #1, #111
bulletCD:
	bulletFib 2, #0, #160, #1, #230
bulletCE:
	bulletFib 2, #0, #215, #2, #90
bulletCF:
	bulletFib 2, #1, #20, #2, #204
bulletD0:
	bulletFib 2, #0, #146, #1, #98
bulletD1:
	bulletFib 2, #0, #207, #1, #212
bulletD2:
	bulletFib 2, #1, #17, #2, #66
bulletD3:
	bulletFib 2, #1, #89, #2, #173
bulletD4:
	bulletFib 2, #0, #181, #1, #82
bulletD5:
	bulletFib 2, #0, #252, #1, #189
bulletD6:
	bulletFib 2, #1, #73, #2, #36
bulletD7:
	bulletFib 2, #1, #154, #2, #136
bulletD8:
	bulletFib 2, #0, #213, #1, #63
bulletD9:
	bulletFib 2, #1, #38, #1, #162
bulletDA:
	bulletFib 2, #1, #125, #2, #2
bulletDB:
	bulletFib 2, #1, #216, #2, #93
bulletDC:
	bulletFib 2, #0, #243, #1, #40
bulletDD:
	bulletFib 2, #1, #78, #1, #131
bulletDE:
	bulletFib 2, #1, #173, #1, #218
bulletDF:
	bulletFib 2, #2, #17, #2, #44
bulletE0:
	bulletFib 2, #1, #15, #1, #15
bulletE1:
	bulletFib 2, #1, #114, #1, #97
bulletE2:
	bulletFib 2, #1, #218, #1, #173
bulletE3:
	bulletFib 2, #2, #69, #1, #245
bulletE4:
	bulletFib 2, #1, #40, #0, #243
bulletE5:
	bulletFib 2, #1, #147, #1, #58
bulletE6:
	bulletFib 2, #2, #2, #1, #125
bulletE7:
	bulletFib 2, #2, #115, #1, #186
bulletE8:
	bulletFib 2, #1, #63, #0, #213
bulletE9:
	bulletFib 2, #1, #176, #1, #17
bulletEA:
	bulletFib 2, #2, #36, #1, #73
bulletEB:
	bulletFib 2, #2, #156, #1, #122
bulletEC:
	bulletFib 2, #1, #82, #0, #181
bulletED:
	bulletFib 2, #1, #201, #0, #230
bulletEE:
	bulletFib 2, #2, #66, #1, #17
bulletEF:
	bulletFib 2, #2, #190, #1, #55
bulletF0:
	bulletFib 2, #1, #98, #0, #146
bulletF1:
	bulletFib 2, #1, #221, #0, #184
bulletF2:
	bulletFib 2, #2, #90, #0, #215
bulletF3:
	bulletFib 2, #2, #217, #0, #240
bulletF4:
	bulletFib 2, #1, #111, #0, #111
bulletF5:
	bulletFib 2, #1, #237, #0, #136
bulletF6:
	bulletFib 2, #2, #108, #0, #155
bulletF7:
	bulletFib 2, #2, #237, #0, #168
bulletF8:
	bulletFib 2, #1, #120, #0, #74
bulletF9:
	bulletFib 2, #1, #248, #0, #87
bulletFA:
	bulletFib 2, #2, #121, #0, #93
bulletFB:
	bulletFib 2, #2, #250, #0, #94
bulletFC:
	bulletFib 2, #1, #126, #0, #37
bulletFD:
	bulletFib 2, #1, #254, #0, #37
bulletFE:
	bulletFib 2, #2, #127, #0, #31
bulletFF:
	bulletFib 2, #2, #255, #0, #18

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
