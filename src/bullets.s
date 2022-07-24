.include "bullets.h"
.include "lib.h"
.include "player.h"
.include "sprites.h"

BULLETS_VARIETIES=8
MAX_ENEMY_BULLETS=56

.zeropage
quickBulletX: .res 1
quickBulletY: .res 1
bulletType: .res 4
octant: .res 1
bulletAngle: .res 1
numberOfBullets: .res 1
Bullets_spriteBank: .res BULLETS_VARIETIES

.data
isEnemyBulletActive: .res MAX_ENEMY_BULLETS
enemyBulletHitbox1: .res MAX_ENEMY_BULLETS
enemyBulletHitbox2: .res MAX_ENEMY_BULLETS
enemyBulletBehaviorH: .res MAX_ENEMY_BULLETS
enemyBulletBehaviorL: .res MAX_ENEMY_BULLETS
enemyBulletXH: .res MAX_ENEMY_BULLETS
enemyBulletXL: .res MAX_ENEMY_BULLETS
enemyBulletYH: .res MAX_ENEMY_BULLETS
enemyBulletYL: .res MAX_ENEMY_BULLETS
enemyBulletMetasprite: .res MAX_ENEMY_BULLETS
Bullets_diameter: .res MAX_ENEMY_BULLETS
Bullets_isCoin: .res MAX_ENEMY_BULLETS
Bullets_isBullet: .res MAX_ENEMY_BULLETS
Bullets_i: .res MAX_ENEMY_BULLETS

.code
Enemy_Bullet:
;push y, x, id
	jsr Enemy_Bullets_getAvailable;c,x(void)
	bcc @bulletsFull;returns clear if full

	pla;retrieve bullet id
	tay ;y is bullet ID

	lda romEnemyBulletBehaviorH,y
	sta enemyBulletBehaviorH,x
	lda romEnemyBulletBehaviorL,y
	sta enemyBulletBehaviorL,x

	lda #TRUE
	sta Bullets_isBullet,x
	lda #FALSE
	sta Bullets_isCoin,x

	tya ;restore bullet
;now use the lowes 2 bits to get the bullet type loaded during enemy wave
	and #%00000011 
	tay 
	lda bulletType,y
	tay 

	lda romEnemyBulletMetasprite,y;copy metasprite
	sta enemyBulletMetasprite,x
	
	lda romEnemyBulletHitbox1,y;copy hitbox
	sta enemyBulletHitbox1,x
	lda romEnemyBulletHitbox2,y
	sta enemyBulletHitbox2,x

	lda Bullets_diameterROM,y;copy diameter
	sta Bullets_diameter,x

	pla
	sta enemyBulletXH,x
	pla	
	sta enemyBulletYH,x
	rts
@bulletsFull:
	pla
	pla
	pla
	rts

Enemy_Bullets:
;quickBulletY - y coordinate
;save bullet
@bulletLoop:
	jsr Enemy_Bullets_getAvailable
	bcc @bulletsFull;returns clear if full
	lda quickBulletX
	sta enemyBulletXH,x
	lda quickBulletY
	sta enemyBulletYH,x

	pla;retrieve bullet id
	tay ;y is bullet ID

	lda romEnemyBulletBehaviorH,y
	sta enemyBulletBehaviorH,x
	lda romEnemyBulletBehaviorL,y
	sta enemyBulletBehaviorL,x

	lda #TRUE
	sta Bullets_isBullet,x
	lda #FALSE
	sta Bullets_isCoin,x

	tya ;restore ID
	and #%00000011 ;get index
	tay 
	lda bulletType,y;[4]
	tay ;y is type
	
	lda romEnemyBulletMetasprite,y;copy metasprite
	sta enemyBulletMetasprite,x
	
	lda romEnemyBulletHitbox1,y;copy hitboxes
	sta enemyBulletHitbox1,x
	lda romEnemyBulletHitbox2,y
	sta enemyBulletHitbox2,x
	
	lda Bullets_diameterROM,y;copy diameter
	sta Bullets_diameter,x
	
	dec numberOfBullets
	bne @bulletLoop
	rts
@bulletsFull:
;pull id
	pla
	dec numberOfBullets
	bne @bulletsFull
	rts

Enemy_Bullets_getAvailable:; c,x (void)
;loops through bullet collection, finds inactive bullet, sets to active, returns offset
;returns
;x - active offset
;carry clear if full, set if success
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x
	beq @returnBullet
	dex
	bpl @bulletLoop
	clc;mark full
	rts
@returnBullet:
	lda #TRUE;set active
	sta isEnemyBulletActive,x
	sec ;mark success
	rts

updateEnemyBullets:;(void)
;pushes all bullet offsets and functions onto stack and returns
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x
	beq @skipBullet;skip inactive bullets
		cmp #1
		bne @decreaseHold
			txa
			pha; save array index
			lda enemyBulletBehaviorH,x
			pha; push function pointer H
			lda enemyBulletBehaviorL,x
			pha; push function pointer L
@skipBullet:
	dex ;x--
	bpl @bulletLoop ;while x>=0
	rts
@decreaseHold:
	dec isEnemyBulletActive,x
	dex ;x--
	bpl @bulletLoop ;while x>=0
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

Bullets_toCoins:;void(s)

	pla
	tax
	
	lda Bullets_diameter,x
	and #%11111000
	clc
	adc Bullets_i,x
	tay

	lda #SPRITE1E
	sta enemyBulletMetasprite,x
	
	lda enemyBulletYH,x
	clc
	adc #1
	bcc :+
		lda #255
	:sta enemyBulletYH,x

	inc Bullets_i,x
	lda Bullets_i,x
	cmp #16
	bcc @statePersists
		lda #<(Coins_move-1)
		sta enemyBulletBehaviorL,x
		lda #>(Coins_move-1)
		sta enemyBulletBehaviorH,x
@statePersists:
	rts

@toCoinAnimation:

Coins_move:

	pla ;get the argument
	tax
	
	lda Player_xPos_H
	adc #4
	sec
	sbc enemyBulletXH,x
	bcs @playerXGreater

		eor #%11111111
		tay
	
		lda enemyBulletXL,x
		sbc Coin_speed_L,y
		sta enemyBulletXL,x
		
		lda enemyBulletXH,x
		sbc Coin_speed_H,y
		sta enemyBulletXH,x
	
		jmp @doY

@playerXGreater:
	tay

	lda enemyBulletXL,x
	adc Coin_speed_L,y
	sta enemyBulletXL,x
	
	lda enemyBulletXH,x
	adc Coin_speed_H,y
	sta enemyBulletXH,x

@doY:
	sec
	lda Player_yPos_H
	sbc enemyBulletYH,x
	bcc @playerYGreater
		tay

		lda enemyBulletYL,x
		adc Coin_speed_L,y
		sta enemyBulletYL,x
		
		lda enemyBulletYH,x
		adc Coin_speed_H,y
		sta enemyBulletYH,x
		rts
@playerYGreater:
	eor #%11111111
	tay

	lda enemyBulletYL,x
	sbc Coin_speed_L,y
	sta enemyBulletYL,x
	
	lda enemyBulletYH,x
	sbc Coin_speed_H,y
	sta enemyBulletYH,x
@return:
	rts
.rodata

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
	pla
	tax
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
	rts
@clearBullet:
;shift bit out
	lsr isEnemyBulletActive,x
	rts
.endmacro 
Bullet_spriteBank:
	.byte 0, 1, 1, 1, 1, 1, 1, 1
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
romEnemyBulletBehaviorH:
	.byte >(bullet00-1)
	.byte >(bullet01-1)
	.byte >(bullet02-1)
	.byte >(bullet03-1)
	.byte >(bullet04-1)
	.byte >(bullet05-1)
	.byte >(bullet06-1)
	.byte >(bullet07-1)
	.byte >(bullet08-1)
	.byte >(bullet09-1)
	.byte >(bullet0A-1)
	.byte >(bullet0B-1)
	.byte >(bullet0C-1)
	.byte >(bullet0D-1)
	.byte >(bullet0E-1)
	.byte >(bullet0F-1)
	.byte >(bullet10-1)
	.byte >(bullet11-1)
	.byte >(bullet12-1)
	.byte >(bullet13-1)
	.byte >(bullet14-1)
	.byte >(bullet15-1)
	.byte >(bullet16-1)
	.byte >(bullet17-1)
	.byte >(bullet18-1)
	.byte >(bullet19-1)
	.byte >(bullet1A-1)
	.byte >(bullet1B-1)
	.byte >(bullet1C-1)
	.byte >(bullet1D-1)
	.byte >(bullet1E-1)
	.byte >(bullet1F-1)
	.byte >(bullet20-1)
	.byte >(bullet21-1)
	.byte >(bullet22-1)
	.byte >(bullet23-1)
	.byte >(bullet24-1)
	.byte >(bullet25-1)
	.byte >(bullet26-1)
	.byte >(bullet27-1)
	.byte >(bullet28-1)
	.byte >(bullet29-1)
	.byte >(bullet2A-1)
	.byte >(bullet2B-1)
	.byte >(bullet2C-1)
	.byte >(bullet2D-1)
	.byte >(bullet2E-1)
	.byte >(bullet2F-1)
	.byte >(bullet30-1)
	.byte >(bullet31-1)
	.byte >(bullet32-1)
	.byte >(bullet33-1)
	.byte >(bullet34-1)
	.byte >(bullet35-1)
	.byte >(bullet36-1)
	.byte >(bullet37-1)
	.byte >(bullet38-1)
	.byte >(bullet39-1)
	.byte >(bullet3A-1)
	.byte >(bullet3B-1)
	.byte >(bullet3C-1)
	.byte >(bullet3D-1)
	.byte >(bullet3E-1)
	.byte >(bullet3F-1)
	.byte >(bullet40-1)
	.byte >(bullet41-1)
	.byte >(bullet42-1)
	.byte >(bullet43-1)
	.byte >(bullet44-1)
	.byte >(bullet45-1)
	.byte >(bullet46-1)
	.byte >(bullet47-1)
	.byte >(bullet48-1)
	.byte >(bullet49-1)
	.byte >(bullet4A-1)
	.byte >(bullet4B-1)
	.byte >(bullet4C-1)
	.byte >(bullet4D-1)
	.byte >(bullet4E-1)
	.byte >(bullet4F-1)
	.byte >(bullet50-1)
	.byte >(bullet51-1)
	.byte >(bullet52-1)
	.byte >(bullet53-1)
	.byte >(bullet54-1)
	.byte >(bullet55-1)
	.byte >(bullet56-1)
	.byte >(bullet57-1)
	.byte >(bullet58-1)
	.byte >(bullet59-1)
	.byte >(bullet5A-1)
	.byte >(bullet5B-1)
	.byte >(bullet5C-1)
	.byte >(bullet5D-1)
	.byte >(bullet5E-1)
	.byte >(bullet5F-1)
	.byte >(bullet60-1)
	.byte >(bullet61-1)
	.byte >(bullet62-1)
	.byte >(bullet63-1)
	.byte >(bullet64-1)
	.byte >(bullet65-1)
	.byte >(bullet66-1)
	.byte >(bullet67-1)
	.byte >(bullet68-1)
	.byte >(bullet69-1)
	.byte >(bullet6A-1)
	.byte >(bullet6B-1)
	.byte >(bullet6C-1)
	.byte >(bullet6D-1)
	.byte >(bullet6E-1)
	.byte >(bullet6F-1)
	.byte >(bullet70-1)
	.byte >(bullet71-1)
	.byte >(bullet72-1)
	.byte >(bullet73-1)
	.byte >(bullet74-1)
	.byte >(bullet75-1)
	.byte >(bullet76-1)
	.byte >(bullet77-1)
	.byte >(bullet78-1)
	.byte >(bullet79-1)
	.byte >(bullet7A-1)
	.byte >(bullet7B-1)
	.byte >(bullet7C-1)
	.byte >(bullet7D-1)
	.byte >(bullet7E-1)
	.byte >(bullet7F-1)
	.byte >(bullet80-1)
	.byte >(bullet81-1)
	.byte >(bullet82-1)
	.byte >(bullet83-1)
	.byte >(bullet84-1)
	.byte >(bullet85-1)
	.byte >(bullet86-1)
	.byte >(bullet87-1)
	.byte >(bullet88-1)
	.byte >(bullet89-1)
	.byte >(bullet8A-1)
	.byte >(bullet8B-1)
	.byte >(bullet8C-1)
	.byte >(bullet8D-1)
	.byte >(bullet8E-1)
	.byte >(bullet8F-1)
	.byte >(bullet90-1)
	.byte >(bullet91-1)
	.byte >(bullet92-1)
	.byte >(bullet93-1)
	.byte >(bullet94-1)
	.byte >(bullet95-1)
	.byte >(bullet96-1)
	.byte >(bullet97-1)
	.byte >(bullet98-1)
	.byte >(bullet99-1)
	.byte >(bullet9A-1)
	.byte >(bullet9B-1)
	.byte >(bullet9C-1)
	.byte >(bullet9D-1)
	.byte >(bullet9E-1)
	.byte >(bullet9F-1)
	.byte >(bulletA0-1)
	.byte >(bulletA1-1)
	.byte >(bulletA2-1)
	.byte >(bulletA3-1)
	.byte >(bulletA4-1)
	.byte >(bulletA5-1)
	.byte >(bulletA6-1)
	.byte >(bulletA7-1)
	.byte >(bulletA8-1)
	.byte >(bulletA9-1)
	.byte >(bulletAA-1)
	.byte >(bulletAB-1)
	.byte >(bulletAC-1)
	.byte >(bulletAD-1)
	.byte >(bulletAE-1)
	.byte >(bulletAF-1)
	.byte >(bulletB0-1)
	.byte >(bulletB1-1)
	.byte >(bulletB2-1)
	.byte >(bulletB3-1)
	.byte >(bulletB4-1)
	.byte >(bulletB5-1)
	.byte >(bulletB6-1)
	.byte >(bulletB7-1)
	.byte >(bulletB8-1)
	.byte >(bulletB9-1)
	.byte >(bulletBA-1)
	.byte >(bulletBB-1)
	.byte >(bulletBC-1)
	.byte >(bulletBD-1)
	.byte >(bulletBE-1)
	.byte >(bulletBF-1)
	.byte >(bulletC0-1)
	.byte >(bulletC1-1)
	.byte >(bulletC2-1)
	.byte >(bulletC3-1)
	.byte >(bulletC4-1)
	.byte >(bulletC5-1)
	.byte >(bulletC6-1)
	.byte >(bulletC7-1)
	.byte >(bulletC8-1)
	.byte >(bulletC9-1)
	.byte >(bulletCA-1)
	.byte >(bulletCB-1)
	.byte >(bulletCC-1)
	.byte >(bulletCD-1)
	.byte >(bulletCE-1)
	.byte >(bulletCF-1)
	.byte >(bulletD0-1)
	.byte >(bulletD1-1)
	.byte >(bulletD2-1)
	.byte >(bulletD3-1)
	.byte >(bulletD4-1)
	.byte >(bulletD5-1)
	.byte >(bulletD6-1)
	.byte >(bulletD7-1)
	.byte >(bulletD8-1)
	.byte >(bulletD9-1)
	.byte >(bulletDA-1)
	.byte >(bulletDB-1)
	.byte >(bulletDC-1)
	.byte >(bulletDD-1)
	.byte >(bulletDE-1)
	.byte >(bulletDF-1)
	.byte >(bulletE0-1)
	.byte >(bulletE1-1)
	.byte >(bulletE2-1)
	.byte >(bulletE3-1)
	.byte >(bulletE4-1)
	.byte >(bulletE5-1)
	.byte >(bulletE6-1)
	.byte >(bulletE7-1)
	.byte >(bulletE8-1)
	.byte >(bulletE9-1)
	.byte >(bulletEA-1)
	.byte >(bulletEB-1)
	.byte >(bulletEC-1)
	.byte >(bulletED-1)
	.byte >(bulletEE-1)
	.byte >(bulletEF-1)
	.byte >(bulletF0-1)
	.byte >(bulletF1-1)
	.byte >(bulletF2-1)
	.byte >(bulletF3-1)
	.byte >(bulletF4-1)
	.byte >(bulletF5-1)
	.byte >(bulletF6-1)
	.byte >(bulletF7-1)
	.byte >(bulletF8-1)
	.byte >(bulletF9-1)
	.byte >(bulletFA-1)
	.byte >(bulletFB-1)
	.byte >(bulletFC-1)
	.byte >(bulletFD-1)
	.byte >(bulletFE-1)
	.byte >(bulletFF-1)
romEnemyBulletBehaviorL:
	.byte <(bullet00-1)
	.byte <(bullet01-1)
	.byte <(bullet02-1)
	.byte <(bullet03-1)
	.byte <(bullet04-1)
	.byte <(bullet05-1)
	.byte <(bullet06-1)
	.byte <(bullet07-1)
	.byte <(bullet08-1)
	.byte <(bullet09-1)
	.byte <(bullet0A-1)
	.byte <(bullet0B-1)
	.byte <(bullet0C-1)
	.byte <(bullet0D-1)
	.byte <(bullet0E-1)
	.byte <(bullet0F-1)
	.byte <(bullet10-1)
	.byte <(bullet11-1)
	.byte <(bullet12-1)
	.byte <(bullet13-1)
	.byte <(bullet14-1)
	.byte <(bullet15-1)
	.byte <(bullet16-1)
	.byte <(bullet17-1)
	.byte <(bullet18-1)
	.byte <(bullet19-1)
	.byte <(bullet1A-1)
	.byte <(bullet1B-1)
	.byte <(bullet1C-1)
	.byte <(bullet1D-1)
	.byte <(bullet1E-1)
	.byte <(bullet1F-1)
	.byte <(bullet20-1)
	.byte <(bullet21-1)
	.byte <(bullet22-1)
	.byte <(bullet23-1)
	.byte <(bullet24-1)
	.byte <(bullet25-1)
	.byte <(bullet26-1)
	.byte <(bullet27-1)
	.byte <(bullet28-1)
	.byte <(bullet29-1)
	.byte <(bullet2A-1)
	.byte <(bullet2B-1)
	.byte <(bullet2C-1)
	.byte <(bullet2D-1)
	.byte <(bullet2E-1)
	.byte <(bullet2F-1)
	.byte <(bullet30-1)
	.byte <(bullet31-1)
	.byte <(bullet32-1)
	.byte <(bullet33-1)
	.byte <(bullet34-1)
	.byte <(bullet35-1)
	.byte <(bullet36-1)
	.byte <(bullet37-1)
	.byte <(bullet38-1)
	.byte <(bullet39-1)
	.byte <(bullet3A-1)
	.byte <(bullet3B-1)
	.byte <(bullet3C-1)
	.byte <(bullet3D-1)
	.byte <(bullet3E-1)
	.byte <(bullet3F-1)
	.byte <(bullet40-1)
	.byte <(bullet41-1)
	.byte <(bullet42-1)
	.byte <(bullet43-1)
	.byte <(bullet44-1)
	.byte <(bullet45-1)
	.byte <(bullet46-1)
	.byte <(bullet47-1)
	.byte <(bullet48-1)
	.byte <(bullet49-1)
	.byte <(bullet4A-1)
	.byte <(bullet4B-1)
	.byte <(bullet4C-1)
	.byte <(bullet4D-1)
	.byte <(bullet4E-1)
	.byte <(bullet4F-1)
	.byte <(bullet50-1)
	.byte <(bullet51-1)
	.byte <(bullet52-1)
	.byte <(bullet53-1)
	.byte <(bullet54-1)
	.byte <(bullet55-1)
	.byte <(bullet56-1)
	.byte <(bullet57-1)
	.byte <(bullet58-1)
	.byte <(bullet59-1)
	.byte <(bullet5A-1)
	.byte <(bullet5B-1)
	.byte <(bullet5C-1)
	.byte <(bullet5D-1)
	.byte <(bullet5E-1)
	.byte <(bullet5F-1)
	.byte <(bullet60-1)
	.byte <(bullet61-1)
	.byte <(bullet62-1)
	.byte <(bullet63-1)
	.byte <(bullet64-1)
	.byte <(bullet65-1)
	.byte <(bullet66-1)
	.byte <(bullet67-1)
	.byte <(bullet68-1)
	.byte <(bullet69-1)
	.byte <(bullet6A-1)
	.byte <(bullet6B-1)
	.byte <(bullet6C-1)
	.byte <(bullet6D-1)
	.byte <(bullet6E-1)
	.byte <(bullet6F-1)
	.byte <(bullet70-1)
	.byte <(bullet71-1)
	.byte <(bullet72-1)
	.byte <(bullet73-1)
	.byte <(bullet74-1)
	.byte <(bullet75-1)
	.byte <(bullet76-1)
	.byte <(bullet77-1)
	.byte <(bullet78-1)
	.byte <(bullet79-1)
	.byte <(bullet7A-1)
	.byte <(bullet7B-1)
	.byte <(bullet7C-1)
	.byte <(bullet7D-1)
	.byte <(bullet7E-1)
	.byte <(bullet7F-1)
	.byte <(bullet80-1)
	.byte <(bullet81-1)
	.byte <(bullet82-1)
	.byte <(bullet83-1)
	.byte <(bullet84-1)
	.byte <(bullet85-1)
	.byte <(bullet86-1)
	.byte <(bullet87-1)
	.byte <(bullet88-1)
	.byte <(bullet89-1)
	.byte <(bullet8A-1)
	.byte <(bullet8B-1)
	.byte <(bullet8C-1)
	.byte <(bullet8D-1)
	.byte <(bullet8E-1)
	.byte <(bullet8F-1)
	.byte <(bullet90-1)
	.byte <(bullet91-1)
	.byte <(bullet92-1)
	.byte <(bullet93-1)
	.byte <(bullet94-1)
	.byte <(bullet95-1)
	.byte <(bullet96-1)
	.byte <(bullet97-1)
	.byte <(bullet98-1)
	.byte <(bullet99-1)
	.byte <(bullet9A-1)
	.byte <(bullet9B-1)
	.byte <(bullet9C-1)
	.byte <(bullet9D-1)
	.byte <(bullet9E-1)
	.byte <(bullet9F-1)
	.byte <(bulletA0-1)
	.byte <(bulletA1-1)
	.byte <(bulletA2-1)
	.byte <(bulletA3-1)
	.byte <(bulletA4-1)
	.byte <(bulletA5-1)
	.byte <(bulletA6-1)
	.byte <(bulletA7-1)
	.byte <(bulletA8-1)
	.byte <(bulletA9-1)
	.byte <(bulletAA-1)
	.byte <(bulletAB-1)
	.byte <(bulletAC-1)
	.byte <(bulletAD-1)
	.byte <(bulletAE-1)
	.byte <(bulletAF-1)
	.byte <(bulletB0-1)
	.byte <(bulletB1-1)
	.byte <(bulletB2-1)
	.byte <(bulletB3-1)
	.byte <(bulletB4-1)
	.byte <(bulletB5-1)
	.byte <(bulletB6-1)
	.byte <(bulletB7-1)
	.byte <(bulletB8-1)
	.byte <(bulletB9-1)
	.byte <(bulletBA-1)
	.byte <(bulletBB-1)
	.byte <(bulletBC-1)
	.byte <(bulletBD-1)
	.byte <(bulletBE-1)
	.byte <(bulletBF-1)
	.byte <(bulletC0-1)
	.byte <(bulletC1-1)
	.byte <(bulletC2-1)
	.byte <(bulletC3-1)
	.byte <(bulletC4-1)
	.byte <(bulletC5-1)
	.byte <(bulletC6-1)
	.byte <(bulletC7-1)
	.byte <(bulletC8-1)
	.byte <(bulletC9-1)
	.byte <(bulletCA-1)
	.byte <(bulletCB-1)
	.byte <(bulletCC-1)
	.byte <(bulletCD-1)
	.byte <(bulletCE-1)
	.byte <(bulletCF-1)
	.byte <(bulletD0-1)
	.byte <(bulletD1-1)
	.byte <(bulletD2-1)
	.byte <(bulletD3-1)
	.byte <(bulletD4-1)
	.byte <(bulletD5-1)
	.byte <(bulletD6-1)
	.byte <(bulletD7-1)
	.byte <(bulletD8-1)
	.byte <(bulletD9-1)
	.byte <(bulletDA-1)
	.byte <(bulletDB-1)
	.byte <(bulletDC-1)
	.byte <(bulletDD-1)
	.byte <(bulletDE-1)
	.byte <(bulletDF-1)
	.byte <(bulletE0-1)
	.byte <(bulletE1-1)
	.byte <(bulletE2-1)
	.byte <(bulletE3-1)
	.byte <(bulletE4-1)
	.byte <(bulletE5-1)
	.byte <(bulletE6-1)
	.byte <(bulletE7-1)
	.byte <(bulletE8-1)
	.byte <(bulletE9-1)
	.byte <(bulletEA-1)
	.byte <(bulletEB-1)
	.byte <(bulletEC-1)
	.byte <(bulletED-1)
	.byte <(bulletEE-1)
	.byte <(bulletEF-1)
	.byte <(bulletF0-1)
	.byte <(bulletF1-1)
	.byte <(bulletF2-1)
	.byte <(bulletF3-1)
	.byte <(bulletF4-1)
	.byte <(bulletF5-1)
	.byte <(bulletF6-1)
	.byte <(bulletF7-1)
	.byte <(bulletF8-1)
	.byte <(bulletF9-1)
	.byte <(bulletFA-1)
	.byte <(bulletFB-1)
	.byte <(bulletFC-1)
	.byte <(bulletFD-1)
	.byte <(bulletFE-1)
	.byte <(bulletFF-1)
	

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

Coin_speed_L:
	.byte   0,  47,  94, 141, 187, 233,  22,  66, 110, 153, 196, 238,  24,  66, 106, 147
	.byte 186, 226,   9,  47,  85, 122, 159, 195, 231,  11,  46,  81, 115, 148, 182, 214
	.byte 247,  23,  54,  85, 116, 146, 176, 206, 235,   7,  35,  63,  91, 118, 144, 171
	.byte 197, 222, 247,  16,  41,  65,  89, 112, 135, 158, 180, 202, 224, 245,  10,  31
	.byte  52,  72,  91, 111, 130, 149, 167, 186, 204, 221, 239,   0,  17,  33,  49,  65
	.byte  81,  97, 112, 127, 141, 156, 170, 184, 198, 211, 224, 237, 250,   7,  19,  31
	.byte  43,  54,  66,  77,  88,  99, 109, 120, 130, 140, 149, 159, 168, 178, 187, 195
	.byte 204, 212, 221, 229, 237, 244, 252,   4,  11,  18,  25,  32,  38,  45,  51,  57
	.byte  64,  69,  75,  81,  86,  92,  97, 102, 107, 112, 117, 121, 126, 130, 135, 139
	.byte 143, 147, 151, 155, 158, 162, 165, 169, 172, 175, 178, 181, 184, 187, 190, 192
	.byte 195, 197, 200, 202, 204, 206, 209, 211, 213, 215, 216, 218, 220, 222, 223, 225
	.byte 226, 228, 229, 230, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243
	.byte 244, 244, 245, 246, 246, 247, 247, 248, 248, 249, 249, 250, 250, 251, 251, 251
	.byte 252, 252, 252, 253, 253, 253, 253, 253, 254, 254, 254, 254, 254, 254, 255, 255
	.byte 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
	.byte 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,   0,   0,   0
Coin_speed_H:
	.byte   0,   0,   0,   0,   0,   0,   1,   1,   1,   1,   1,   1,   2,   2,   2,   2
	.byte   2,   2,   3,   3,   3,   3,   3,   3,   3,   4,   4,   4,   4,   4,   4,   4
	.byte   4,   5,   5,   5,   5,   5,   5,   5,   5,   6,   6,   6,   6,   6,   6,   6
	.byte   6,   6,   6,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   8,   8
	.byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   9,   9,   9,   9,   9
	.byte   9,   9,   9,   9,   9,   9,   9,   9,   9,   9,   9,   9,   9,  10,  10,  10
	.byte  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10
	.byte  10,  10,  10,  10,  10,  10,  10,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11
	.byte  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  11,  12,  12,  12

