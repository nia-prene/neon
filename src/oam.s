.include "lib.h"

.include "oam.h"

.include "sprites.h"
.include "score.h"
.include "player.h"
.include "shots.h"
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
limit: .res 1


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

		jsr buildHitbox

@buildWithoutHitbox:
	
	jsr OAM_buildBullets

	jsr OAM_buildPlayer

	jsr buildEnemies
	
	jsr buildPlayerBullets

	jsr OAM_clearRemaining

@oamFull:
	rts

buildHitbox:;x(x,a)
PLAYER_HITBOX_Y_OFFSET=10
PLAYER_HITBOX_X_OFFSET=2

	clc
	lda Player_yPos_H
	sta buildY

	lda Player_xPos_H
	sta buildX

	ldx Hitbox_sprite

	jmp OAM_build; void(a)

.proc OAM_buildBullets
LIMIT=48

	lda #LIMIT; set sprite limit for layer
	sta limit

	lda bulletShuffle; shuffle bullets
	adc #(MAX_ENEMY_BULLETS/5) * 3; 3/5ths item collection
	cmp #MAX_ENEMY_BULLETS-1
	bcc @storeShuffle
		sbc #MAX_ENEMY_BULLETS-1; make sure no wrap
@storeShuffle:
	sta bulletShuffle

	tax; set as initial iterator
	jsr firstPass; y(x) |

	ldx #MAX_ENEMY_BULLETS-1
	jsr secondPass; void(y,x) |
	rts

.align 64
firstPass:
	ldy OAM_index
@bulletLoop:

	lda isEnemyBulletActive,x; if active
	cmp #1
	bne @skipBullet
		
	lda limit
	beq @full

		lda #$24

		sta OAM+OFFSET_TILE,y
		
		sec
		lda enemyBulletYH,x
		sbc #4
		sta OAM+OFFSET_Y,y

		lda enemyBulletXH,x
		sbc #4
		sta OAM+OFFSET_X,y

		lda #%11
		sta OAM+OFFSET_ATTRIBUTE,y
		
		dec limit

		iny
		iny
		iny
		iny

@skipBullet:
	dex
	bpl @bulletLoop

@full:	
	sty OAM_index
	rts


secondPass:

	ldy OAM_index
	
@bulletLoop:

	lda isEnemyBulletActive,x
	cmp #1; if active and visible
	bne @skipBullet
		
	lda limit; and not full
	beq @full


		lda #$24

		sta OAM+OFFSET_TILE,y
		
		sec
		lda enemyBulletYH,x
		sbc #4
		sta OAM+OFFSET_Y,y

		lda enemyBulletXH,x
		sbc #4
		sta OAM+OFFSET_X,y

		lda #%11
		sta OAM+OFFSET_ATTRIBUTE,y

		dec limit

		iny
		iny
		iny
		iny

@skipBullet:
	dex
	cpx bulletShuffle
	bne @bulletLoop

@full:	
	sty OAM_index
	rts

.endproc


OAM_buildPlayer:; void()

	lda Player_yPos_H
	sta buildY

	lda Player_xPos_H
	sta buildX

	ldx Player_sprite
	jmp OAM_build; void(x) |

buildPlayerBullets:

	ldy #SHOTS_MAX-1

@loop:
	lda isActive,y
	beq @skipEnemy

		lda bulletY,y
		sta buildY
		lda bulletX,y
		sta buildX
		ldx bulletSprite,y

		sty yReg
		jsr OAM_build; void(x)
		ldy yReg

@skipEnemy:	

	dey
	bpl @loop
	rts

buildEnemies:
	
	ldy #MAX_ENEMIES-1

@enemyLoop:
	lda isEnemyActive,y
	beq @skipEnemy
		
		lda enemyYH,y
		sta buildY
		lda enemyXH,y
		sta buildX
		lda enemyPalette,y
		sta buildPalette
		
		ldx enemyMetasprite,y

		sty yReg
		jsr OAM_build; void(x)
		ldy yReg

@skipEnemy:

	dey
	bpl @enemyLoop
	rts


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
	;jmp buildSpritesShort

.endproc

.align 128
OAM_build:;void (x) 
;a - metasprite to build

	lda spritesL,x
	sta spritePointer
	lda spritesH,x
	sta spritePointer+1
	
	ldy #0; sprite 0
	
	ldx OAM_index; get the index
	beq @finished; return if sprites are full

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


OAM_clearRemaining:
;arguments
;x-starting point to clear
	
	ldx OAM_index
	beq @done; already clear

		lda #$FF; clear y with FF

	@clearOAM:

		sta OAM+OFFSET_Y,x

		inx
		inx
		inx
		inx

		bne @clearOAM
@done:
	rts

OAM_beginDMA:
;reset oam address
	lda #$00
	sta OAMADDR
;begin transfer by writing high byte of OAM
	lda #OAM_LOCATION
	sta OAMDMA
	rts
