.include "bullets.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "bombs.h"
.include "enemies.h"

BULLETS_VARIETIES=8
MAX_ENEMY_BULLETS=128

.zeropage
;arguments
quickBulletX: .res 1
quickBulletY: .res 1
numberOfBullets: .res 1
Bullets_fastForwardFrames:.res 1
Charms_framesElapsed: .res 1

;pointers
Bullets_move: .res 2

;locals
octant: .res 1
bulletAngle: .res 1
;Bullets_spriteBank: .res BULLETS_VARIETIES
Bullets_willSpritesShuffle: .res 1

.data
Charms_isActive: .res 1

enemyBulletBehaviorH: .res 1
enemyBulletBehaviorL: .res 1

isEnemyBulletActive: .res MAX_ENEMY_BULLETS
enemyBulletXH: .res MAX_ENEMY_BULLETS
enemyBulletXL: .res MAX_ENEMY_BULLETS
enemyBulletYH: .res MAX_ENEMY_BULLETS
enemyBulletYL: .res MAX_ENEMY_BULLETS
enemyBulletMetasprite: .res 1
Bullets_ID: .res MAX_ENEMY_BULLETS

.code

	

	jsr Enemy_Bullets_getAvailable;c,y(void) | x
	bcc @bulletsFull;returns clear if full
	
		lda enemyXH,x; copy enemy y and x
		sta enemyBulletXH,y
		lda enemyYH,x
		sta enemyBulletYH,y;
	
	
		lda Bullets_fastForwardFrames; it may be fastForwarded
		sta isEnemyBulletActive,y
	
		rts
@bulletsFull:
	pla
	rts

Bullets_newGroup:; void(a,x) |
	sta numberOfBullets

	lda enemyYH,x; copy enemy y and x
	sta quickBulletY
	lda enemyXH,x
	sta quickBulletX
	
@bulletLoop:
	
	jsr Enemy_Bullets_getAvailable; y(x) | x
	bcc @bulletsFull;returns clear if full

	pla;retrieve bullet id
	sta Bullets_ID,y

	lda quickBulletY
	sta enemyBulletYH,y
	lda quickBulletX
	sta enemyBulletXH,y

	lda Bullets_fastForwardFrames
	sta isEnemyBulletActive,y
	
	dec numberOfBullets
	bne @bulletLoop

	rts
@bulletsFull:
;pull id
	pla
	dec numberOfBullets
	bne @bulletsFull
	rts

Enemy_Bullets_getAvailable:
Bullets_new:; c,y() | x
;returns x - active offset
;returns carry clear if full

	ldy #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,y
	bne @nextBullet
		sec ;mark success
		rts
@nextBullet:
	dey
	bpl @bulletLoop
	clc;mark full
	rts

updateEnemyBullets:;(void)
;pushes all bullet offsets and functions onto stack and returns

	ldx #MAX_ENEMY_BULLETS-1

Bullets_moveLoop:
	lda isEnemyBulletActive,x
	beq Bullets_tickDown;skip inactive bullets
		
		sec
		sbc #1
		beq :+; don't store a zero
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


;used to see if charms are still on screen
Charms_getActive:
	lda Charms_isActive
	rts


aimBullet:
;arguments:
;quickBulletX
;quickBulletY
;returns:
;a - degree from 0-256 to shoot bullet. use this degree to fetch correct bullet
	sec
	lda Player_xPos_H
	sbc quickBulletX
	bcs *+4
	eor #$ff
	tax
	rol octant
	lda Player_yPos_H
	adc #10
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
	sta bulletAngle
	rts

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

	ldx #MAX_ENEMY_BULLETS-1

@charmLoop:

	lda isEnemyBulletActive,x
	beq @nextCharm
		
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
	bulletFib 3, #2, #0, #0, #0 
bullet01:
	bulletFib 3, #2, #127, #0, #15 
bullet02:
	bulletFib 3, #1, #255, #0, #25 
bullet03:
	bulletFib 3, #2, #253, #0, #56 
bullet04:
	bulletFib 3, #1, #253, #0, #50 
bullet05:
	bulletFib 3, #2, #123, #0, #78 
bullet06:
	bulletFib 3, #1, #250, #0, #75 
bullet07:
	bulletFib 3, #2, #244, #0, #131 
bullet08:
	bulletFib 3, #1, #246, #0, #99 
bullet09:
	bulletFib 3, #2, #112, #0, #140 
bullet0A:
	bulletFib 3, #1, #240, #0, #124 
bullet0B:
	bulletFib 3, #2, #228, #0, #204 
bullet0C:
	bulletFib 3, #1, #233, #0, #148 
bullet0D:
	bulletFib 3, #2, #95, #0, #200 
bullet0E:
	bulletFib 3, #1, #226, #0, #172 
bullet0F:
	bulletFib 3, #2, #204, #1, #20 
bullet10:
	bulletFib 3, #1, #217, #0, #195 
bullet11:
	bulletFib 3, #2, #73, #1, #3 
bullet12:
	bulletFib 3, #1, #206, #0, #218 
bullet13:
	bulletFib 3, #2, #173, #1, #89 
bullet14:
	bulletFib 3, #1, #195, #0, #241 
bullet15:
	bulletFib 3, #2, #44, #1, #59 
bullet16:
	bulletFib 3, #1, #183, #1, #7 
bullet17:
	bulletFib 3, #2, #136, #1, #154 
bullet18:
	bulletFib 3, #1, #169, #1, #28 
bullet19:
	bulletFib 3, #2, #11, #1, #112 
bullet1A:
	bulletFib 3, #1, #155, #1, #48 
bullet1B:
	bulletFib 3, #2, #93, #1, #216 
bullet1C:
	bulletFib 3, #1, #139, #1, #68 
bullet1D:
	bulletFib 3, #1, #228, #1, #162 
bullet1E:
	bulletFib 3, #1, #123, #1, #87 
bullet1F:
	bulletFib 3, #2, #44, #2, #17 
bullet20:
	bulletFib 3, #1, #106, #1, #106 
bullet21:
	bulletFib 3, #1, #185, #1, #207 
bullet22:
	bulletFib 3, #1, #87, #1, #123 
bullet23:
	bulletFib 3, #1, #245, #2, #69 
bullet24:
	bulletFib 3, #1, #68, #1, #139 
bullet25:
	bulletFib 3, #1, #137, #1, #248 
bullet26:
	bulletFib 3, #1, #48, #1, #155 
bullet27:
	bulletFib 3, #1, #186, #2, #115 
bullet28:
	bulletFib 3, #1, #28, #1, #169 
bullet29:
	bulletFib 3, #1, #86, #2, #28 
bullet2A:
	bulletFib 3, #1, #7, #1, #183 
bullet2B:
	bulletFib 3, #1, #122, #2, #156 
bullet2C:
	bulletFib 3, #0, #241, #1, #195 
bullet2D:
	bulletFib 3, #1, #31, #2, #59 
bullet2E:
	bulletFib 3, #0, #218, #1, #206 
bullet2F:
	bulletFib 3, #1, #55, #2, #190 
bullet30:
	bulletFib 3, #0, #195, #1, #217 
bullet31:
	bulletFib 3, #0, #230, #2, #85 
bullet32:
	bulletFib 3, #0, #172, #1, #226 
bullet33:
	bulletFib 3, #0, #240, #2, #217 
bullet34:
	bulletFib 3, #0, #148, #1, #233 
bullet35:
	bulletFib 3, #0, #170, #2, #104 
bullet36:
	bulletFib 3, #0, #124, #1, #240 
bullet37:
	bulletFib 3, #0, #168, #2, #237 
bullet38:
	bulletFib 3, #0, #99, #1, #246 
bullet39:
	bulletFib 3, #0, #109, #2, #118 
bullet3A:
	bulletFib 3, #0, #75, #1, #250 
bullet3B:
	bulletFib 3, #0, #94, #2, #250 
bullet3C:
	bulletFib 3, #0, #50, #1, #253 
bullet3D:
	bulletFib 3, #0, #47, #2, #126 
bullet3E:
	bulletFib 3, #0, #25, #1, #255 
bullet3F:
	bulletFib 3, #0, #18, #2, #255 
bullet40:
	bulletFib 4, #0, #0, #2, #0 
bullet41:
	bulletFib 4, #0, #15, #2, #127 
bullet42:
	bulletFib 4, #0, #25, #1, #255 
bullet43:
	bulletFib 4, #0, #56, #2, #253 
bullet44:
	bulletFib 4, #0, #50, #1, #253 
bullet45:
	bulletFib 4, #0, #78, #2, #123 
bullet46:
	bulletFib 4, #0, #75, #1, #250 
bullet47:
	bulletFib 4, #0, #131, #2, #244 
bullet48:
	bulletFib 4, #0, #99, #1, #246 
bullet49:
	bulletFib 4, #0, #140, #2, #112 
bullet4A:
	bulletFib 4, #0, #124, #1, #240 
bullet4B:
	bulletFib 4, #0, #204, #2, #228 
bullet4C:
	bulletFib 4, #0, #148, #1, #233 
bullet4D:
	bulletFib 4, #0, #200, #2, #95 
bullet4E:
	bulletFib 4, #0, #172, #1, #226 
bullet4F:
	bulletFib 4, #1, #20, #2, #204 
bullet50:
	bulletFib 4, #0, #195, #1, #217 
bullet51:
	bulletFib 4, #1, #3, #2, #73 
bullet52:
	bulletFib 4, #0, #218, #1, #206 
bullet53:
	bulletFib 4, #1, #89, #2, #173 
bullet54:
	bulletFib 4, #0, #241, #1, #195 
bullet55:
	bulletFib 4, #1, #59, #2, #44 
bullet56:
	bulletFib 4, #1, #7, #1, #183 
bullet57:
	bulletFib 4, #1, #154, #2, #136 
bullet58:
	bulletFib 4, #1, #28, #1, #169 
bullet59:
	bulletFib 4, #1, #112, #2, #11 
bullet5A:
	bulletFib 4, #1, #48, #1, #155 
bullet5B:
	bulletFib 4, #1, #216, #2, #93 
bullet5C:
	bulletFib 4, #1, #68, #1, #139 
bullet5D:
	bulletFib 4, #1, #162, #1, #228 
bullet5E:
	bulletFib 4, #1, #87, #1, #123 
bullet5F:
	bulletFib 4, #2, #17, #2, #44 
bullet60:
	bulletFib 4, #1, #106, #1, #106 
bullet61:
	bulletFib 4, #1, #207, #1, #185 
bullet62:
	bulletFib 4, #1, #123, #1, #87 
bullet63:
	bulletFib 4, #2, #69, #1, #245 
bullet64:
	bulletFib 4, #1, #139, #1, #68 
bullet65:
	bulletFib 4, #1, #248, #1, #137 
bullet66:
	bulletFib 4, #1, #155, #1, #48 
bullet67:
	bulletFib 4, #2, #115, #1, #186 
bullet68:
	bulletFib 4, #1, #169, #1, #28 
bullet69:
	bulletFib 4, #2, #28, #1, #86 
bullet6A:
	bulletFib 4, #1, #183, #1, #7 
bullet6B:
	bulletFib 4, #2, #156, #1, #122 
bullet6C:
	bulletFib 4, #1, #195, #0, #241 
bullet6D:
	bulletFib 4, #2, #59, #1, #31 
bullet6E:
	bulletFib 4, #1, #206, #0, #218 
bullet6F:
	bulletFib 4, #2, #190, #1, #55 
bullet70:
	bulletFib 4, #1, #217, #0, #195 
bullet71:
	bulletFib 4, #2, #85, #0, #230 
bullet72:
	bulletFib 4, #1, #226, #0, #172 
bullet73:
	bulletFib 4, #2, #217, #0, #240 
bullet74:
	bulletFib 4, #1, #233, #0, #148 
bullet75:
	bulletFib 4, #2, #104, #0, #170 
bullet76:
	bulletFib 4, #1, #240, #0, #124 
bullet77:
	bulletFib 4, #2, #237, #0, #168 
bullet78:
	bulletFib 4, #1, #246, #0, #99 
bullet79:
	bulletFib 4, #2, #118, #0, #109 
bullet7A:
	bulletFib 4, #1, #250, #0, #75 
bullet7B:
	bulletFib 4, #2, #250, #0, #94 
bullet7C:
	bulletFib 4, #1, #253, #0, #50 
bullet7D:
	bulletFib 4, #2, #126, #0, #47 
bullet7E:
	bulletFib 4, #1, #255, #0, #25 
bullet7F:
	bulletFib 4, #2, #255, #0, #18 
bullet80:
	bulletFib 1, #2, #0, #0, #0 
bullet81:
	bulletFib 1, #2, #127, #0, #15 
bullet82:
	bulletFib 1, #1, #255, #0, #25 
bullet83:
	bulletFib 1, #2, #253, #0, #56 
bullet84:
	bulletFib 1, #1, #253, #0, #50 
bullet85:
	bulletFib 1, #2, #123, #0, #78 
bullet86:
	bulletFib 1, #1, #250, #0, #75 
bullet87:
	bulletFib 1, #2, #244, #0, #131 
bullet88:
	bulletFib 1, #1, #246, #0, #99 
bullet89:
	bulletFib 1, #2, #112, #0, #140 
bullet8A:
	bulletFib 1, #1, #240, #0, #124 
bullet8B:
	bulletFib 1, #2, #228, #0, #204 
bullet8C:
	bulletFib 1, #1, #233, #0, #148 
bullet8D:
	bulletFib 1, #2, #95, #0, #200 
bullet8E:
	bulletFib 1, #1, #226, #0, #172 
bullet8F:
	bulletFib 1, #2, #204, #1, #20 
bullet90:
	bulletFib 1, #1, #217, #0, #195 
bullet91:
	bulletFib 1, #2, #73, #1, #3 
bullet92:
	bulletFib 1, #1, #206, #0, #218 
bullet93:
	bulletFib 1, #2, #173, #1, #89 
bullet94:
	bulletFib 1, #1, #195, #0, #241 
bullet95:
	bulletFib 1, #2, #44, #1, #59 
bullet96:
	bulletFib 1, #1, #183, #1, #7 
bullet97:
	bulletFib 1, #2, #136, #1, #154 
bullet98:
	bulletFib 1, #1, #169, #1, #28 
bullet99:
	bulletFib 1, #2, #11, #1, #112 
bullet9A:
	bulletFib 1, #1, #155, #1, #48 
bullet9B:
	bulletFib 1, #2, #93, #1, #216 
bullet9C:
	bulletFib 1, #1, #139, #1, #68 
bullet9D:
	bulletFib 1, #1, #228, #1, #162 
bullet9E:
	bulletFib 1, #1, #123, #1, #87 
bullet9F:
	bulletFib 1, #2, #44, #2, #17 
bulletA0:
	bulletFib 1, #1, #106, #1, #106 
bulletA1:
	bulletFib 1, #1, #185, #1, #207 
bulletA2:
	bulletFib 1, #1, #87, #1, #123 
bulletA3:
	bulletFib 1, #1, #245, #2, #69 
bulletA4:
	bulletFib 1, #1, #68, #1, #139 
bulletA5:
	bulletFib 1, #1, #137, #1, #248 
bulletA6:
	bulletFib 1, #1, #48, #1, #155 
bulletA7:
	bulletFib 1, #1, #186, #2, #115 
bulletA8:
	bulletFib 1, #1, #28, #1, #169 
bulletA9:
	bulletFib 1, #1, #86, #2, #28 
bulletAA:
	bulletFib 1, #1, #7, #1, #183 
bulletAB:
	bulletFib 1, #1, #122, #2, #156 
bulletAC:
	bulletFib 1, #0, #241, #1, #195 
bulletAD:
	bulletFib 1, #1, #31, #2, #59 
bulletAE:
	bulletFib 1, #0, #218, #1, #206 
bulletAF:
	bulletFib 1, #1, #55, #2, #190 
bulletB0:
	bulletFib 1, #0, #195, #1, #217 
bulletB1:
	bulletFib 1, #0, #230, #2, #85 
bulletB2:
	bulletFib 1, #0, #172, #1, #226 
bulletB3:
	bulletFib 1, #0, #240, #2, #217 
bulletB4:
	bulletFib 1, #0, #148, #1, #233 
bulletB5:
	bulletFib 1, #0, #170, #2, #104 
bulletB6:
	bulletFib 1, #0, #124, #1, #240 
bulletB7:
	bulletFib 1, #0, #168, #2, #237 
bulletB8:
	bulletFib 1, #0, #99, #1, #246 
bulletB9:
	bulletFib 1, #0, #109, #2, #118 
bulletBA:
	bulletFib 1, #0, #75, #1, #250 
bulletBB:
	bulletFib 1, #0, #94, #2, #250 
bulletBC:
	bulletFib 1, #0, #50, #1, #253 
bulletBD:
	bulletFib 1, #0, #47, #2, #126 
bulletBE:
	bulletFib 1, #0, #25, #1, #255 
bulletBF:
	bulletFib 1, #0, #18, #2, #255 
bulletC0:
	bulletFib 2, #0, #0, #2, #0 
bulletC1:
	bulletFib 2, #0, #15, #2, #127 
bulletC2:
	bulletFib 2, #0, #25, #1, #255 
bulletC3:
	bulletFib 2, #0, #56, #2, #253 
bulletC4:
	bulletFib 2, #0, #50, #1, #253 
bulletC5:
	bulletFib 2, #0, #78, #2, #123 
bulletC6:
	bulletFib 2, #0, #75, #1, #250 
bulletC7:
	bulletFib 2, #0, #131, #2, #244 
bulletC8:
	bulletFib 2, #0, #99, #1, #246 
bulletC9:
	bulletFib 2, #0, #140, #2, #112 
bulletCA:
	bulletFib 2, #0, #124, #1, #240 
bulletCB:
	bulletFib 2, #0, #204, #2, #228 
bulletCC:
	bulletFib 2, #0, #148, #1, #233 
bulletCD:
	bulletFib 2, #0, #200, #2, #95 
bulletCE:
	bulletFib 2, #0, #172, #1, #226 
bulletCF:
	bulletFib 2, #1, #20, #2, #204 
bulletD0:
	bulletFib 2, #0, #195, #1, #217 
bulletD1:
	bulletFib 2, #1, #3, #2, #73 
bulletD2:
	bulletFib 2, #0, #218, #1, #206 
bulletD3:
	bulletFib 2, #1, #89, #2, #173 
bulletD4:
	bulletFib 2, #0, #241, #1, #195 
bulletD5:
	bulletFib 2, #1, #59, #2, #44 
bulletD6:
	bulletFib 2, #1, #7, #1, #183 
bulletD7:
	bulletFib 2, #1, #154, #2, #136 
bulletD8:
	bulletFib 2, #1, #28, #1, #169 
bulletD9:
	bulletFib 2, #1, #112, #2, #11 
bulletDA:
	bulletFib 2, #1, #48, #1, #155 
bulletDB:
	bulletFib 2, #1, #216, #2, #93 
bulletDC:
	bulletFib 2, #1, #68, #1, #139 
bulletDD:
	bulletFib 2, #1, #162, #1, #228 
bulletDE:
	bulletFib 2, #1, #87, #1, #123 
bulletDF:
	bulletFib 2, #2, #17, #2, #44 
bulletE0:
	bulletFib 2, #1, #106, #1, #106 
bulletE1:
	bulletFib 2, #1, #207, #1, #185 
bulletE2:
	bulletFib 2, #1, #123, #1, #87 
bulletE3:
	bulletFib 2, #2, #69, #1, #245 
bulletE4:
	bulletFib 2, #1, #139, #1, #68 
bulletE5:
	bulletFib 2, #1, #248, #1, #137 
bulletE6:
	bulletFib 2, #1, #155, #1, #48 
bulletE7:
	bulletFib 2, #2, #115, #1, #186 
bulletE8:
	bulletFib 2, #1, #169, #1, #28 
bulletE9:
	bulletFib 2, #2, #28, #1, #86 
bulletEA:
	bulletFib 2, #1, #183, #1, #7 
bulletEB:
	bulletFib 2, #2, #156, #1, #122 
bulletEC:
	bulletFib 2, #1, #195, #0, #241 
bulletED:
	bulletFib 2, #2, #59, #1, #31 
bulletEE:
	bulletFib 2, #1, #206, #0, #218 
bulletEF:
	bulletFib 2, #2, #190, #1, #55 
bulletF0:
	bulletFib 2, #1, #217, #0, #195 
bulletF1:
	bulletFib 2, #2, #85, #0, #230 
bulletF2:
	bulletFib 2, #1, #226, #0, #172 
bulletF3:
	bulletFib 2, #2, #217, #0, #240 
bulletF4:
	bulletFib 2, #1, #233, #0, #148 
bulletF5:
	bulletFib 2, #2, #104, #0, #170 
bulletF6:
	bulletFib 2, #1, #240, #0, #124 
bulletF7:
	bulletFib 2, #2, #237, #0, #168 
bulletF8:
	bulletFib 2, #1, #246, #0, #99 
bulletF9:
	bulletFib 2, #2, #118, #0, #109 
bulletFA:
	bulletFib 2, #1, #250, #0, #75 
bulletFB:
	bulletFib 2, #2, #250, #0, #94 
bulletFC:
	bulletFib 2, #1, #253, #0, #50 
bulletFD:
	bulletFib 2, #2, #126, #0, #47 
bulletFE:
	bulletFib 2, #1, #255, #0, #25 
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
