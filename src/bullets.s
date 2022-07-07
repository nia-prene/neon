.include "bullets.h"
.include "lib.h"
.include "player.h"
.include "sprites.h"
.include "speed.h"

.zeropage

quickBulletX: .res 1
quickBulletY: .res 1
bulletType: .res 4
octant: .res 1
bulletAngle: .res 1
numberOfBullets: .res 1

.data
MAX_ENEMY_BULLETS=56
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
	tya ;restore bullet
;now use the lowes 2 bits to get the bullet type loaded during enemy wave
	and #%00000011 
	tay 
	lda bulletType,y
	tay 
;copy metasprite
	lda romEnemyBulletMetasprite,y
	sta enemyBulletMetasprite,x
;copy hitboxes
	lda romEnemyBulletHitbox1,y
	sta enemyBulletHitbox1,x
	lda romEnemyBulletHitbox2,y
	sta enemyBulletHitbox2,x
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
	tya ;restore ID
	and #%00000011 ;get index
	tay 
	lda bulletType,y;[4]
	tay ;y is type
	;copy metasprite
	lda romEnemyBulletMetasprite,y
	sta enemyBulletMetasprite,x
	;copy hitboxes
	lda romEnemyBulletHitbox1,y
	sta enemyBulletHitbox1,x
	lda romEnemyBulletHitbox2,y
	sta enemyBulletHitbox2,x
	sta $102
	dec numberOfBullets
	bne @bulletLoop
	rts
@bulletsFull:
;pull id
	pla
	sta $102
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

.rodata

;the following attributes are the bullets type. The bullet type is stored with the enemy wave, so that each bullet can change sprite, width, etc throughout gameplay at the beginning of each enemy wave, where it will remain constant until the next enemy wave is loaded.
romEnemyBulletHitbox1:
	.byte 2, 4
romEnemyBulletHitbox2:
	.byte 4, 8
romEnemyBulletMetasprite:
	.byte BULLET_SPRITE_0, BULLET_SPRITE_1

.macro bulletFib quadrant, xOffset_L, xOffset_H, yOffset_L, yOffset_H 
	pla
	tax
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	lda enemyBulletYL,x
	sbc Speed_string+yOffset_L
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	lda enemyBulletYL,x
	adc Speed_string+yOffset_L
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYL,x
	lda enemyBulletYH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sbc Speed_string+yOffset_H
	bcc @clearBullet
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	adc Speed_string+yOffset_H
	bcs @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYH,x
	lda enemyBulletXL,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc Speed_string+xOffset_L
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc Speed_string+xOffset_L
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXL,x
	lda enemyBulletXH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc Speed_string+xOffset_H
	bcs @clearBullet
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc Speed_string+xOffset_H
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

bullet00:
	bulletFib 3, 0, 1, 2, 3 
bullet01:
	bulletFib 3, 4, 5, 6, 7 
bullet02:
	bulletFib 3, 8, 9, 10, 11 
bullet03:
	bulletFib 3, 12, 13, 14, 15 
bullet04:
	bulletFib 3, 16, 17, 18, 19 
bullet05:
	bulletFib 3, 20, 21, 22, 23 
bullet06:
	bulletFib 3, 24, 25, 26, 27 
bullet07:
	bulletFib 3, 28, 29, 30, 31 
bullet08:
	bulletFib 3, 32, 33, 34, 35 
bullet09:
	bulletFib 3, 36, 37, 38, 39 
bullet0A:
	bulletFib 3, 40, 41, 42, 43 
bullet0B:
	bulletFib 3, 44, 45, 46, 47 
bullet0C:
	bulletFib 3, 48, 49, 50, 51 
bullet0D:
	bulletFib 3, 52, 53, 54, 55 
bullet0E:
	bulletFib 3, 56, 57, 58, 59 
bullet0F:
	bulletFib 3, 60, 61, 62, 63 
bullet10:
	bulletFib 3, 64, 65, 66, 67 
bullet11:
	bulletFib 3, 68, 69, 70, 71 
bullet12:
	bulletFib 3, 72, 73, 74, 75 
bullet13:
	bulletFib 3, 76, 77, 78, 79 
bullet14:
	bulletFib 3, 80, 81, 82, 83 
bullet15:
	bulletFib 3, 84, 85, 86, 87 
bullet16:
	bulletFib 3, 88, 89, 90, 91 
bullet17:
	bulletFib 3, 92, 93, 94, 95 
bullet18:
	bulletFib 3, 96, 97, 98, 99 
bullet19:
	bulletFib 3, 100, 101, 102, 103 
bullet1A:
	bulletFib 3, 104, 105, 106, 107 
bullet1B:
	bulletFib 3, 108, 109, 110, 111 
bullet1C:
	bulletFib 3, 112, 113, 114, 115 
bullet1D:
	bulletFib 3, 116, 117, 118, 119 
bullet1E:
	bulletFib 3, 120, 121, 122, 123 
bullet1F:
	bulletFib 3, 124, 125, 126, 127 
bullet20:
	bulletFib 3, 128, 129, 130, 131 
bullet21:
	bulletFib 3, 132, 133, 134, 135 
bullet22:
	bulletFib 3, 136, 137, 138, 139 
bullet23:
	bulletFib 3, 140, 141, 142, 143 
bullet24:
	bulletFib 3, 144, 145, 146, 147 
bullet25:
	bulletFib 3, 148, 149, 150, 151 
bullet26:
	bulletFib 3, 152, 153, 154, 155 
bullet27:
	bulletFib 3, 156, 157, 158, 159 
bullet28:
	bulletFib 3, 160, 161, 162, 163 
bullet29:
	bulletFib 3, 164, 165, 166, 167 
bullet2A:
	bulletFib 3, 168, 169, 170, 171 
bullet2B:
	bulletFib 3, 172, 173, 174, 175 
bullet2C:
	bulletFib 3, 176, 177, 178, 179 
bullet2D:
	bulletFib 3, 180, 181, 182, 183 
bullet2E:
	bulletFib 3, 184, 185, 186, 187 
bullet2F:
	bulletFib 3, 188, 189, 190, 191 
bullet30:
	bulletFib 3, 192, 193, 194, 195 
bullet31:
	bulletFib 3, 196, 197, 198, 199 
bullet32:
	bulletFib 3, 200, 201, 202, 203 
bullet33:
	bulletFib 3, 204, 205, 206, 207 
bullet34:
	bulletFib 3, 208, 209, 210, 211 
bullet35:
	bulletFib 3, 212, 213, 214, 215 
bullet36:
	bulletFib 3, 216, 217, 218, 219 
bullet37:
	bulletFib 3, 220, 221, 222, 223 
bullet38:
	bulletFib 3, 224, 225, 226, 227 
bullet39:
	bulletFib 3, 228, 229, 230, 231 
bullet3A:
	bulletFib 3, 232, 233, 234, 235 
bullet3B:
	bulletFib 3, 236, 237, 238, 239 
bullet3C:
	bulletFib 3, 240, 241, 242, 243 
bullet3D:
	bulletFib 3, 244, 245, 246, 247 
bullet3E:
	bulletFib 3, 248, 249, 250, 251 
bullet3F:
	bulletFib 3, 252, 253, 254, 255 
bullet40:
	bulletFib 4, 2, 3, 0, 1 
bullet41:
	bulletFib 4, 6, 7, 4, 5 
bullet42:
	bulletFib 4, 10, 11, 8, 9 
bullet43:
	bulletFib 4, 14, 15, 12, 13 
bullet44:
	bulletFib 4, 18, 19, 16, 17 
bullet45:
	bulletFib 4, 22, 23, 20, 21 
bullet46:
	bulletFib 4, 26, 27, 24, 25 
bullet47:
	bulletFib 4, 30, 31, 28, 29 
bullet48:
	bulletFib 4, 34, 35, 32, 33 
bullet49:
	bulletFib 4, 38, 39, 36, 37 
bullet4A:
	bulletFib 4, 42, 43, 40, 41 
bullet4B:
	bulletFib 4, 46, 47, 44, 45 
bullet4C:
	bulletFib 4, 50, 51, 48, 49 
bullet4D:
	bulletFib 4, 54, 55, 52, 53 
bullet4E:
	bulletFib 4, 58, 59, 56, 57 
bullet4F:
	bulletFib 4, 62, 63, 60, 61 
bullet50:
	bulletFib 4, 66, 67, 64, 65 
bullet51:
	bulletFib 4, 70, 71, 68, 69 
bullet52:
	bulletFib 4, 74, 75, 72, 73 
bullet53:
	bulletFib 4, 78, 79, 76, 77 
bullet54:
	bulletFib 4, 82, 83, 80, 81 
bullet55:
	bulletFib 4, 86, 87, 84, 85 
bullet56:
	bulletFib 4, 90, 91, 88, 89 
bullet57:
	bulletFib 4, 94, 95, 92, 93 
bullet58:
	bulletFib 4, 98, 99, 96, 97 
bullet59:
	bulletFib 4, 102, 103, 100, 101 
bullet5A:
	bulletFib 4, 106, 107, 104, 105 
bullet5B:
	bulletFib 4, 110, 111, 108, 109 
bullet5C:
	bulletFib 4, 114, 115, 112, 113 
bullet5D:
	bulletFib 4, 118, 119, 116, 117 
bullet5E:
	bulletFib 4, 122, 123, 120, 121 
bullet5F:
	bulletFib 4, 126, 127, 124, 125 
bullet60:
	bulletFib 4, 130, 131, 128, 129 
bullet61:
	bulletFib 4, 134, 135, 132, 133 
bullet62:
	bulletFib 4, 138, 139, 136, 137 
bullet63:
	bulletFib 4, 142, 143, 140, 141 
bullet64:
	bulletFib 4, 146, 147, 144, 145 
bullet65:
	bulletFib 4, 150, 151, 148, 149 
bullet66:
	bulletFib 4, 154, 155, 152, 153 
bullet67:
	bulletFib 4, 158, 159, 156, 157 
bullet68:
	bulletFib 4, 162, 163, 160, 161 
bullet69:
	bulletFib 4, 166, 167, 164, 165 
bullet6A:
	bulletFib 4, 170, 171, 168, 169 
bullet6B:
	bulletFib 4, 174, 175, 172, 173 
bullet6C:
	bulletFib 4, 178, 179, 176, 177 
bullet6D:
	bulletFib 4, 182, 183, 180, 181 
bullet6E:
	bulletFib 4, 186, 187, 184, 185 
bullet6F:
	bulletFib 4, 190, 191, 188, 189 
bullet70:
	bulletFib 4, 194, 195, 192, 193 
bullet71:
	bulletFib 4, 198, 199, 196, 197 
bullet72:
	bulletFib 4, 202, 203, 200, 201 
bullet73:
	bulletFib 4, 206, 207, 204, 205 
bullet74:
	bulletFib 4, 210, 211, 208, 209 
bullet75:
	bulletFib 4, 214, 215, 212, 213 
bullet76:
	bulletFib 4, 218, 219, 216, 217 
bullet77:
	bulletFib 4, 222, 223, 220, 221 
bullet78:
	bulletFib 4, 226, 227, 224, 225 
bullet79:
	bulletFib 4, 230, 231, 228, 229 
bullet7A:
	bulletFib 4, 234, 235, 232, 233 
bullet7B:
	bulletFib 4, 238, 239, 236, 237 
bullet7C:
	bulletFib 4, 242, 243, 240, 241 
bullet7D:
	bulletFib 4, 246, 247, 244, 245 
bullet7E:
	bulletFib 4, 250, 251, 248, 249 
bullet7F:
	bulletFib 4, 254, 255, 252, 253 
bullet80:
	bulletFib 1, 0, 1, 2, 3 
bullet81:
	bulletFib 1, 4, 5, 6, 7 
bullet82:
	bulletFib 1, 8, 9, 10, 11 
bullet83:
	bulletFib 1, 12, 13, 14, 15 
bullet84:
	bulletFib 1, 16, 17, 18, 19 
bullet85:
	bulletFib 1, 20, 21, 22, 23 
bullet86:
	bulletFib 1, 24, 25, 26, 27 
bullet87:
	bulletFib 1, 28, 29, 30, 31 
bullet88:
	bulletFib 1, 32, 33, 34, 35 
bullet89:
	bulletFib 1, 36, 37, 38, 39 
bullet8A:
	bulletFib 1, 40, 41, 42, 43 
bullet8B:
	bulletFib 1, 44, 45, 46, 47 
bullet8C:
	bulletFib 1, 48, 49, 50, 51 
bullet8D:
	bulletFib 1, 52, 53, 54, 55 
bullet8E:
	bulletFib 1, 56, 57, 58, 59 
bullet8F:
	bulletFib 1, 60, 61, 62, 63 
bullet90:
	bulletFib 1, 64, 65, 66, 67 
bullet91:
	bulletFib 1, 68, 69, 70, 71 
bullet92:
	bulletFib 1, 72, 73, 74, 75 
bullet93:
	bulletFib 1, 76, 77, 78, 79 
bullet94:
	bulletFib 1, 80, 81, 82, 83 
bullet95:
	bulletFib 1, 84, 85, 86, 87 
bullet96:
	bulletFib 1, 88, 89, 90, 91 
bullet97:
	bulletFib 1, 92, 93, 94, 95 
bullet98:
	bulletFib 1, 96, 97, 98, 99 
bullet99:
	bulletFib 1, 100, 101, 102, 103 
bullet9A:
	bulletFib 1, 104, 105, 106, 107 
bullet9B:
	bulletFib 1, 108, 109, 110, 111 
bullet9C:
	bulletFib 1, 112, 113, 114, 115 
bullet9D:
	bulletFib 1, 116, 117, 118, 119 
bullet9E:
	bulletFib 1, 120, 121, 122, 123 
bullet9F:
	bulletFib 1, 124, 125, 126, 127 
bulletA0:
	bulletFib 1, 128, 129, 130, 131 
bulletA1:
	bulletFib 1, 132, 133, 134, 135 
bulletA2:
	bulletFib 1, 136, 137, 138, 139 
bulletA3:
	bulletFib 1, 140, 141, 142, 143 
bulletA4:
	bulletFib 1, 144, 145, 146, 147 
bulletA5:
	bulletFib 1, 148, 149, 150, 151 
bulletA6:
	bulletFib 1, 152, 153, 154, 155 
bulletA7:
	bulletFib 1, 156, 157, 158, 159 
bulletA8:
	bulletFib 1, 160, 161, 162, 163 
bulletA9:
	bulletFib 1, 164, 165, 166, 167 
bulletAA:
	bulletFib 1, 168, 169, 170, 171 
bulletAB:
	bulletFib 1, 172, 173, 174, 175 
bulletAC:
	bulletFib 1, 176, 177, 178, 179 
bulletAD:
	bulletFib 1, 180, 181, 182, 183 
bulletAE:
	bulletFib 1, 184, 185, 186, 187 
bulletAF:
	bulletFib 1, 188, 189, 190, 191 
bulletB0:
	bulletFib 1, 192, 193, 194, 195 
bulletB1:
	bulletFib 1, 196, 197, 198, 199 
bulletB2:
	bulletFib 1, 200, 201, 202, 203 
bulletB3:
	bulletFib 1, 204, 205, 206, 207 
bulletB4:
	bulletFib 1, 208, 209, 210, 211 
bulletB5:
	bulletFib 1, 212, 213, 214, 215 
bulletB6:
	bulletFib 1, 216, 217, 218, 219 
bulletB7:
	bulletFib 1, 220, 221, 222, 223 
bulletB8:
	bulletFib 1, 224, 225, 226, 227 
bulletB9:
	bulletFib 1, 228, 229, 230, 231 
bulletBA:
	bulletFib 1, 232, 233, 234, 235 
bulletBB:
	bulletFib 1, 236, 237, 238, 239 
bulletBC:
	bulletFib 1, 240, 241, 242, 243 
bulletBD:
	bulletFib 1, 244, 245, 246, 247 
bulletBE:
	bulletFib 1, 248, 249, 250, 251 
bulletBF:
	bulletFib 1, 252, 253, 254, 255 
bulletC0:
	bulletFib 2, 2, 3, 0, 1 
bulletC1:
	bulletFib 2, 6, 7, 4, 5 
bulletC2:
	bulletFib 2, 10, 11, 8, 9 
bulletC3:
	bulletFib 2, 14, 15, 12, 13 
bulletC4:
	bulletFib 2, 18, 19, 16, 17 
bulletC5:
	bulletFib 2, 22, 23, 20, 21 
bulletC6:
	bulletFib 2, 26, 27, 24, 25 
bulletC7:
	bulletFib 2, 30, 31, 28, 29 
bulletC8:
	bulletFib 2, 34, 35, 32, 33 
bulletC9:
	bulletFib 2, 38, 39, 36, 37 
bulletCA:
	bulletFib 2, 42, 43, 40, 41 
bulletCB:
	bulletFib 2, 46, 47, 44, 45 
bulletCC:
	bulletFib 2, 50, 51, 48, 49 
bulletCD:
	bulletFib 2, 54, 55, 52, 53 
bulletCE:
	bulletFib 2, 58, 59, 56, 57 
bulletCF:
	bulletFib 2, 62, 63, 60, 61 
bulletD0:
	bulletFib 2, 66, 67, 64, 65 
bulletD1:
	bulletFib 2, 70, 71, 68, 69 
bulletD2:
	bulletFib 2, 74, 75, 72, 73 
bulletD3:
	bulletFib 2, 78, 79, 76, 77 
bulletD4:
	bulletFib 2, 82, 83, 80, 81 
bulletD5:
	bulletFib 2, 86, 87, 84, 85 
bulletD6:
	bulletFib 2, 90, 91, 88, 89 
bulletD7:
	bulletFib 2, 94, 95, 92, 93 
bulletD8:
	bulletFib 2, 98, 99, 96, 97 
bulletD9:
	bulletFib 2, 102, 103, 100, 101 
bulletDA:
	bulletFib 2, 106, 107, 104, 105 
bulletDB:
	bulletFib 2, 110, 111, 108, 109 
bulletDC:
	bulletFib 2, 114, 115, 112, 113 
bulletDD:
	bulletFib 2, 118, 119, 116, 117 
bulletDE:
	bulletFib 2, 122, 123, 120, 121 
bulletDF:
	bulletFib 2, 126, 127, 124, 125 
bulletE0:
	bulletFib 2, 130, 131, 128, 129 
bulletE1:
	bulletFib 2, 134, 135, 132, 133 
bulletE2:
	bulletFib 2, 138, 139, 136, 137 
bulletE3:
	bulletFib 2, 142, 143, 140, 141 
bulletE4:
	bulletFib 2, 146, 147, 144, 145 
bulletE5:
	bulletFib 2, 150, 151, 148, 149 
bulletE6:
	bulletFib 2, 154, 155, 152, 153 
bulletE7:
	bulletFib 2, 158, 159, 156, 157 
bulletE8:
	bulletFib 2, 162, 163, 160, 161 
bulletE9:
	bulletFib 2, 166, 167, 164, 165 
bulletEA:
	bulletFib 2, 170, 171, 168, 169 
bulletEB:
	bulletFib 2, 174, 175, 172, 173 
bulletEC:
	bulletFib 2, 178, 179, 176, 177 
bulletED:
	bulletFib 2, 182, 183, 180, 181 
bulletEE:
	bulletFib 2, 186, 187, 184, 185 
bulletEF:
	bulletFib 2, 190, 191, 188, 189 
bulletF0:
	bulletFib 2, 194, 195, 192, 193 
bulletF1:
	bulletFib 2, 198, 199, 196, 197 
bulletF2:
	bulletFib 2, 202, 203, 200, 201 
bulletF3:
	bulletFib 2, 206, 207, 204, 205 
bulletF4:
	bulletFib 2, 210, 211, 208, 209 
bulletF5:
	bulletFib 2, 214, 215, 212, 213 
bulletF6:
	bulletFib 2, 218, 219, 216, 217 
bulletF7:
	bulletFib 2, 222, 223, 220, 221 
bulletF8:
	bulletFib 2, 226, 227, 224, 225 
bulletF9:
	bulletFib 2, 230, 231, 228, 229 
bulletFA:
	bulletFib 2, 234, 235, 232, 233 
bulletFB:
	bulletFib 2, 238, 239, 236, 237 
bulletFC:
	bulletFib 2, 242, 243, 240, 241 
bulletFD:
	bulletFib 2, 246, 247, 244, 245 
bulletFE:
	bulletFib 2, 250, 251, 248, 249 
bulletFF:
	bulletFib 2, 254, 255, 252, 253 
	
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
