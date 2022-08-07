.include "lib.h"

.include "oam.h"

.include "sprites.h"
.include "score.h"
.include "player.h"
.include "playerbullets.h"
.include "enemies.h"
.include "bullets.h"
.include "bombs.h"

OAM_LOCATION = 02 ;located at $0200, expects hibyte
OAMADDR = $2003;(aaaa aaaa) OAM read/write address
OAMDATA = $2004;(dddd dddd)	OAM data read/write
OAMDMA = $4014;(aaaa aaaa)OAM DMA high address
MAX_OVERFLOW_FRAMES=8;
.zeropage
o: .res 1 	;general purpose iterator, increased once a frame
buildX: .res 1
buildY: .res 1
buildPalette: .res 1
spritePointer: .res 2

Sprite0_destination: .res 1

.segment "OAM"
OAM: .res 256

.code
.proc OAM_initSprite0
SPRITE_Y=238
SPRITE_TILE=$20
SPRITE_ATTRIBUTE=%01100000;flip and place behind
SPRITE_X=112
	lda #SPRITE_Y
	sta OAM
	lda #SPRITE_TILE
	sta OAM+1
	lda #SPRITE_ATTRIBUTE
	sta OAM+2
	lda #SPRITE_X
	sta OAM+3
	rts
.endproc

Sprite0_setSplit:
	sta OAM
	rts

Sprite0_setDestination:
	sta Sprite0_destination
	rts

OAM_build:;c (c,a)
;builds oam 
;call with carry set to exclude player
;a - gamepad
;returns carry clear if oam overflow
	inc o ;module iterator
	ldx #4;skip sprite 0
	
	lda #%01000000
	bit Bombs_timeElapsed ;if time > 128
	php
	bvc @buildBulletsUnderPlayer
	
		jsr buildEnemyBullets
		bcs @oamFull

@buildBulletsUnderPlayer:
	
	lda Player_willRender
	beq @buildWithoutPlayer

		lda Hitbox_sprite;see if hitbox renders first
		beq @buildWithoutHitbox
			jsr buildHitbox
			bcs @oamFull
	@buildWithoutHitbox:

	jsr OAM_buildPlayer
	bcs @oamFull

@buildWithoutPlayer:

	plp ;if time < 128
	bvs @bulletsUnderPlayer
	
		jsr buildEnemyBullets
		bcs @oamFull

@bulletsUnderPlayer:
	jsr buildEnemies
	bcs @oamFull
	jsr buildPlayerBullets
	bcs @oamFull
	jsr OAM_clearRemaining
	rts
@oamFull:
	rts

buildHitbox:;x(x,a)
PLAYER_HITBOX_Y_OFFSET=10
PLAYER_HITBOX_X_OFFSET=2

	lda #TERMINATE;terminate
	pha

	lda Hitbox_sprite
	pha

	clc
	lda Player_yPos_H
	adc #PLAYER_HITBOX_Y_OFFSET
	pha
	lda Player_xPos_H
	adc #PLAYER_HITBOX_X_OFFSET
	pha
	lda #00
	pha
	jmp buildSpritesShort

buildEnemyBullets:
	lda #TERMINATE;terminate
	pha

	lda o ;alternate building forward and backward 
	ror
	bcc @buildForward

@buildBackward:
	ldy #MAX_ENEMY_BULLETS-1
@loopBackward:
	lda isEnemyBulletActive,y
	beq @skipBullet
		lda enemyBulletMetasprite,y
		pha
		lda enemyBulletYH,y
		pha
		lda enemyBulletXH,y
		pha
		lda #0; palette implied
		pha
@skipBullet:
	dey
	bpl @loopBackward
	jmp buildSpritesShort

@buildForward:
	ldy #0
@loopForward:
	lda isEnemyBulletActive,y
	beq @next
		lda enemyBulletMetasprite,y
		pha
		lda enemyBulletYH,y
		pha
		lda enemyBulletXH,y
		pha
		lda #0; palette implied
		pha
@next:
	iny
	cpy #MAX_ENEMY_BULLETS
	bcc @loopForward
	jmp buildSpritesShort


OAM_buildPlayer:
;prepares player sprite for oam
;first push a null to terminate 
;then push sprite, y, x, palette
	lda #TERMINATE;terminator
	pha
	lda Player_sprite
	pha
	lda Player_yPos_H
	pha
	lda Player_xPos_H
	pha
	lda #0;palette implied
	pha
	jmp buildSprites

buildPlayerBullets:
	lda #TERMINATE;terminate
	pha
	lda o
	ror
	ror
	ror
	bcs @buildLoop1
@buildLoop0:
	ldy #MAX_PLAYER_BULLETS-1
@loop0:
	lda isActive,y
	beq :+
		lda bulletSprite,y
		pha
		lda bulletY,y
		pha
		lda bulletX,y
		pha
		lda #0;palette
		pha
:	dey
	bpl @loop0
	jmp buildSpritesShort
@buildLoop1:
	ldy #0
@loop1:
	lda isActive,y
	beq :+
		lda bulletSprite,y
		pha
		lda bulletY,y
		pha
		lda bulletX,y
		pha
		lda #0;palette
		pha
:	iny
	cpy #MAX_PLAYER_BULLETS
	bcc @loop1
	jmp buildSpritesShort

buildEnemies:
	lda #TERMINATE
	pha
	ldy #MAX_ENEMIES-1
@enemyLoop:
	lda isEnemyActive,y
	beq @skipEnemy
	lda enemyMetasprite,y
	pha
	lda enemyYH,y
	pha
	lda enemyXH,y
	pha
	lda enemyPalette,y
	pha
@skipEnemy:
	dey
	bpl @enemyLoop
	jmp buildSprites

.proc OAM_buildPause
XPOS=110
YPOS=64
	lda #TERMINATE
	pha
	lda #SPRITE17
	pha
	lda #YPOS
	pha
	lda #XPOS
	pha
	lda #0
	pha
	jmp buildSpritesShort

.endproc

buildSprites:
;builds collections of sprites
;push tile, y, x, palette
;pull and use in reverse order
;returns
;x - current OAM position
	pla
	cmp #TERMINATE
	beq @return
@metaspriteLoop:
	sta buildPalette
	pla
	sta buildX
	pla
	sta buildY
	pla
	tay
	lda spritesL,y
	sta spritePointer
	lda spritesH,y
	sta spritePointer+1
	ldy #0
	clc
	lda (spritePointer),y
	@tileLoop:
		adc buildY
		bcs @yOverflow
	@returnY:
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		ora buildPalette
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		adc buildX
		bcs @xOverflow
	@returnX:
		sta OAM,x
		inx
		beq @oamFull
		iny
		lda (spritePointer),y
		cmp #TERMINATE
		bne @tileLoop
	pla
	cmp #TERMINATE
	bne @metaspriteLoop
@return:
	clc ;build successful
	rts
@yOverflow:
	clc
	lda #$ff
	jmp @returnY
@xOverflow:
	clc
	lda #$ff
	jmp @returnX
@oamFull:
	pla ;null or palette
	cmp #TERMINATE
	beq @returnFull
	pla ;x
	pla ;y
	pla ;sprite
	jmp @oamFull
@returnFull:
	sec ;set full
	rts

buildSpritesShort:;x(x)
;builds collections of sprites
;push metasprite, y, x, palette
;pull and use in reverse order
;returns
;x - current OAM position

;if first byte = null, no sprites
	pla
	cmp #TERMINATE
	beq @return
@metaspriteLoop:
	pla
	sta buildX
	pla
	sta buildY
	pla
	tay
	lda spritesL,y
	sta spritePointer
	lda spritesH,y
	sta spritePointer+1
	ldy #0
	clc
	@tileLoop:
		lda buildY
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		sta OAM,x
		inx
		iny
		lda (spritePointer),y
		adc buildX
		bcs @xOverflow
	@returnX:
		sta OAM,x
		inx
		beq @oamFull
		iny
		lda (spritePointer),y
		cmp #TERMINATE
		bne @tileLoop
	pla
	cmp #TERMINATE
	bne @metaspriteLoop
@return:
	clc
	rts
@xOverflow:
	clc
	lda #$ff
	jmp @returnX
@oamFull:
	pla ;null or palette
	cmp #TERMINATE
	beq @returnFull
	pla ;x
	pla ;y
	pla ;sprite
	jmp @oamFull
@returnFull:
	sec
	rts

OAM_clearRemaining:
;arguments
;x-starting point to clear
	lda #$ff
@clearOAM:
	sta OAM,x
	inx
	inx
	inx
	sta OAM,x
	inx
	bne @clearOAM
	rts

OAM_beginDMA:
;reset oam address
	lda #$00
	sta OAMADDR
;begin transfer by writing high byte of OAM
	lda #OAM_LOCATION
	sta OAMDMA
	rts
