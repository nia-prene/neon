.include "lib.h"

.include "playerbullets.h"

.include "player.h"
.include "sprites.h"

.zeropage
MAX_PLAYER_BULLETS = 15
bulletX: .res MAX_PLAYER_BULLETS 
bulletY: .res MAX_PLAYER_BULLETS 
PlayerBullet_width: .res MAX_PLAYER_BULLETS
bulletSprite: .res MAX_PLAYER_BULLETS
PlayerBullet_damage: .res MAX_PLAYER_BULLETS
isActive: .res MAX_PLAYER_BULLETS
pressingShoot: .res 1
i: .res 1 ;module iterator

.code
PlayerBullets_shoot:;(controller poll)
B_BUTTON=%01000000
	and #B_BUTTON
	beq @notShooting
		inc pressingShoot
		lda pressingShoot
		and #%00000011
		bne @return
			inc i;increase module iterator
			ldy Player_powerLevel
		@shotLoop:
		;jump to all active shot types
			lda @shotType_H,y
			pha
			lda @shotType_L,y
			pha
			dey
			bpl @shotLoop
			rts
@notShooting:
	lda #$ff
	sta pressingShoot
@return:
	rts
@shotType_L:
	.byte <(shotType00-1)
	.byte <(shotType01-1)
	.byte <(shotType02-1)
@shotType_H:
	.byte >(shotType00-1)
	.byte >(shotType01-1)
	.byte >(shotType02-1)

getAvailableBullet:
;returns
;x - available bullet
;returns clear carry if fail
;find empty bullet starting with slot 0
	ldx #MAX_PLAYER_BULLETS-1
@findEmptyBullet:
	lda isActive,x
	beq @initializeBullet
	dex
;while x >=0 
	bpl @findEmptyBullet
;no empty bullet
	clc
	rts
@initializeBullet:
	lda #TRUE
	sta isActive,x
	sec
	rts

PlayerBullets_move:;void (void)
;moves player bullets up screen
BULLET_SPEED = 18
;start with last bullet
	ldx #MAX_PLAYER_BULLETS-1
@bulletLoop:
	lda isActive,x;if inactive, skip
	beq @skipBullet
	ror
	ror ;bit 2 set means enemy hit
	bcs @clearBullet
	sec ;y = y + speed
	lda bulletY,x
	sbc #BULLET_SPEED
	bcc @clearBullet ;if off screen
	sta bulletY,x
@skipBullet:
	dex ;x--
	bpl @bulletLoop;while x>=0
	rts
@clearBullet:
	lda #FALSE
	sta isActive,x
	dex ;x-- continue loop
	bpl @bulletLoop;while x >=0
	rts
	
.proc shotType00
Y_OFFSET=24
X_OFFSET=4
DAMAGE=3
WIDTH=16
	jsr getAvailableBullet
	bcc @return
	lda playerX_H
	sbc #X_OFFSET
	sta bulletX,x
	lda playerY_H
	sbc #Y_OFFSET
	bcc @bulletOffscreen
	sta bulletY,x
	lda i
	and #%1
	tay
	lda @starSprites,y
	sta bulletSprite,x
	lda #DAMAGE
	sta PlayerBullet_damage,x
	lda #WIDTH
	sta PlayerBullet_width,x
@return:
	rts
@bulletOffscreen:
	lda #FALSE
	sta isActive,x
	rts
@starSprites:
	.byte LARGE_STAR, SPRITE21
.endproc

.proc shotType01
X_OFFSET=8
Y_OFFSET=16
DAMAGE=2
WIDTH=8
;start with left bullet
	jsr getAvailableBullet
	bcc @return
;calculate x offset
	lda playerX_H
	sbc #X_OFFSET
	bcc @bullet1Offscreen
	sta bulletX,x
	lda playerY_H
	sbc #Y_OFFSET
	bcc @bullet1Offscreen
	sta bulletY,x;y offset
	lda #PLAYER_BEAM
	sta bulletSprite,x;sprite
	lda #DAMAGE
	sta PlayerBullet_damage,x
	lda #WIDTH
	sta PlayerBullet_width,x
@bullet2:
	jsr getAvailableBullet
	bcc @return
	lda playerY_H
	sbc #Y_OFFSET
	bcc @bullet2Offscreen
	sta bulletY,x
	clc
	lda playerX_H
	adc #X_OFFSET
	bcs @bullet2Offscreen
	sta bulletX,x;x offset
	lda #PLAYER_BEAM
	sta bulletSprite,x;sprite
	lda #DAMAGE
	sta PlayerBullet_damage,x
	lda #WIDTH
	sta PlayerBullet_width,x
@return:
	rts
@bullet1Offscreen:
	lda #FALSE
	sta isActive,x
	jmp @bullet2
@bullet2Offscreen:
	lda #FALSE
	sta isActive,x
	rts
.endproc

.proc shotType02
X_OFFSET=14
Y_OFFSET=04
DAMAGE=1
WIDTH=8
;start with left bullet
	jsr getAvailableBullet
	bcc @return
	lda playerX_H
	sbc #X_OFFSET
	bcc @bullet1Offscreen
	sta bulletX,x;x offset
	lda playerY_H
	sbc #Y_OFFSET
	bcc @bullet1Offscreen
	sta bulletY,x;y offset
	lda #SMALL_STAR
	sta bulletSprite,x;sprite
	lda #DAMAGE
	sta PlayerBullet_damage,x
	lda #WIDTH
	sta PlayerBullet_width,x
@bullet2:	
	jsr getAvailableBullet
	bcc @return
	lda playerY_H
	sbc #Y_OFFSET
	bcc @bullet2Offscreen
	sta bulletY,x;y offset
	clc
	lda playerX_H
	adc #X_OFFSET
	bcs @bullet2Offscreen
	sta bulletX,x;x offset
	lda #SMALL_STAR
	sta bulletSprite,x;sprite
	lda #DAMAGE
	sta PlayerBullet_damage,x
	lda #WIDTH
	sta PlayerBullet_width,x
@return:
	rts
@bullet1Offscreen:
	lda #FALSE
	sta isActive,x
	jmp @bullet2
@bullet2Offscreen:
	lda #FALSE
	sta isActive,x
	rts
.endproc
