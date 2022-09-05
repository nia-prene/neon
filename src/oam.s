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
bulletShuffle: .res 1
buildX: .res 1
buildY: .res 1
buildPalette: .res 1
spritePointer: .res 2

OAM_index:.res 1

Sprite0_destination: .res 1
.segment "OAM"
OAM: .res 256
OFFSET_Y=0
OFFSET_TILE=1
OFFSET_ATTRIBUTE=2
OFFSET_X=3

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

OAM_build00:;c()
;builds oam 
;call with carry set to exclude player
;a - gamepad
;returns carry clear if oam overflow
	dec o ;module iterator

	lda #4;skip sprite 0
	sta OAM_index
	


	lda Hitbox_sprite;see if hitbox renders first
	beq @buildWithoutHitbox

		;jsr buildHitbox

@buildWithoutHitbox:
	
	;jsr buildEnemyBullets
	bcs @oamFull

	jsr OAM_buildPlayer
	bcs @oamFull

	;jsr buildEnemies
	bcs @oamFull
	
	;jsr buildPlayerBullets
	bcs @oamFull

	;jsr OAM_clearRemaining

@oamFull:
	rts

buildHitbox:;x(x,a)
PLAYER_HITBOX_Y_OFFSET=10
PLAYER_HITBOX_X_OFFSET=2

	lda #TERMINATE;terminate
	pha


	clc
	lda Player_yPos_H
	adc #PLAYER_HITBOX_Y_OFFSET
	pha

	lda Player_xPos_H
	adc #PLAYER_HITBOX_X_OFFSET
	pha

	lda Hitbox_sprite
	pha

	jmp buildSpritesShort

buildEnemyBullets:
LIMIT_BULLETS=48

	stx OAM_index

	lda #TERMINATE;terminate
	pha

	ldx #LIMIT_BULLETS
	
	lda o
	ror
	bcc @shift
		
		lda bulletShuffle
		clc
		adc #MAX_ENEMY_BULLETS
		cmp #MAX_ENEMY_BULLETS-1
		bcc @setIterator
			sbc #MAX_ENEMY_BULLETS-1
			cmp #MAX_ENEMY_BULLETS-1
			bcc	@setIterator
				sbc #MAX_ENEMY_BULLETS-1
				cmp #MAX_ENEMY_BULLETS-1
				bcc	@setIterator
					sbc #MAX_ENEMY_BULLETS-1
					cmp #MAX_ENEMY_BULLETS-1
					bcc	@setIterator
						sbc #MAX_ENEMY_BULLETS-1
						cmp #MAX_ENEMY_BULLETS-1
						bcc	@setIterator
						sbc #MAX_ENEMY_BULLETS-1

@shift:
	clc
	lda bulletShuffle
	adc #MAX_ENEMY_BULLETS/3
	cmp #MAX_ENEMY_BULLETS-1
	bcc @setIterator
		sbc #MAX_ENEMY_BULLETS-1
		cmp #MAX_ENEMY_BULLETS-1
		bcc	@setIterator
			sbc #MAX_ENEMY_BULLETS-1
			cmp #MAX_ENEMY_BULLETS-1
			bcc	@setIterator
				sbc #MAX_ENEMY_BULLETS-1
				cmp #MAX_ENEMY_BULLETS-1
				bcc	@setIterator
					sbc #MAX_ENEMY_BULLETS-1
@setIterator:
	
	sta bulletShuffle
	tay

@initialLoop:

	lda isEnemyBulletActive,y; if active
	cmp #1
	bne @skipBullet
		
		lda enemyBulletYH,y
		pha
		lda enemyBulletXH,y
		pha
		lda #SPRITE02
		pha

		dex
		bmi @full

@skipBullet:

	dey
	bpl @initialLoop
	
	ldy #MAX_ENEMY_BULLETS-1

@remainingLoop:

	lda isEnemyBulletActive,y; if active
	cmp #1
	bne @skip
		
		lda enemyBulletYH,y
		pha
		lda enemyBulletXH,y
		pha
		lda #SPRITE02
		pha

		dex
		bmi @full

@skip:

	dey
	cpy bulletShuffle
	bne @remainingLoop

@full:

	ldx OAM_index
	jmp buildSpritesShort


OAM_buildPlayer:; void()

	lda Player_yPos_H
	sta buildY

	lda Player_xPos_H
	sta buildX

	lda Player_sprite
	jmp OAM_build; void(a) |

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
		lda bulletY,y
		pha
		lda bulletX,y
		pha
		lda bulletSprite,y
		pha
:	dey
	bpl @loop0
	jmp buildSpritesShort
@buildLoop1:
	ldy #0
@loop1:
	lda isActive,y
	beq :+
		lda bulletY,y
		pha
		lda bulletX,y
		pha
		lda bulletSprite,y
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
	lda #YPOS
	pha
	lda #XPOS
	pha
	lda #SPRITE17
	pha
	jmp buildSpritesShort

.endproc

OAM_build:;void (a) 
;a - metasprite to build
	tay; y is Meta Sprite

	lda spritesL,y
	sta spritePointer
	lda spritesH,y
	sta spritePointer+1
	
	ldy #0; sprite 0
	
	ldx OAM_index
	beq @finished

@spriteLoop:

	lda (spritePointer),y
	beq @finished

		sta OAM+OFFSET_TILE,x
		iny
		
		clc
		lda buildY
		adc (spritePointer),y
		sta OAM+OFFSET_Y,x
		iny

		clc
		lda buildX
		adc (spritePointer),y
		sta OAM+OFFSET_X,x
		iny

		lda (spritePointer),y
		ora buildPalette
		sta OAM+OFFSET_ATTRIBUTE,x
		iny

		inx
		inx
		inx
		inx

		beq @finished
		
		jmp @spriteLoop
@finished:

	stx OAM_index
	rts


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
;push y, x, metasprite
;pull and use in reverse order
;returns
;x - current OAM position

;if first byte = null, no sprites
	pla
	cmp #TERMINATE
	beq @return
@metaspriteLoop:

	tay

	pla
	sta buildX
	pla
	sta buildY
	
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
	pla ;null or sprite
	cmp #TERMINATE
	beq @returnFull
	pla ;x
	pla ;y
	jmp @oamFull
@returnFull:
	sec
	rts

OAM_clearRemaining:
;arguments
;x-starting point to clear
	rts
	ldx OAM_index

	lda #$FF; clear y with FF

@clearOAM:

	sta OAM+OFFSET_Y,x

	inx
	inx
	inx
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
