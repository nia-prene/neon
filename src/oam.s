.include "oam.h"

.include "lib.h"

.include "bombs.h"
.include "bullets.h"
.include "enemies.h"
.include "effects.h"
.include "player.h"
.include "powerups.h"
.include "score.h"
.include "shots.h"
.include "sprites.h"

OAM_LOCATION = 02 ;located at $0200, expects hibyte
OAMADDR = $2003;(aaaa aaaa) OAM read/write address
OAMDATA = $2004;(dddd dddd)	OAM data read/write
OAMDMA = $4014;(aaaa aaaa)OAM DMA high address
MAX_OVERFLOW_FRAMES=8;
.zeropage

OAM_index:		.res 1

buildX: 		.res 1
buildY: 		.res 1
buildPalette: 		.res 1
spritePointer: 		.res 2
limit: 			.res 1

bulletShuffle: 		.res 1
enemyShuffle:		.res 1
effectsShuffle:		.res 1


.segment "DATA"

Sprite0_enabled:.res 1
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
SPRITE_TILE=$00
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
	lda #TRUE
	sta Sprite0_enabled
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
	
	lda Sprite0_enabled
	beq :+
		lda #4
	:
	sta OAM_index


	lda Hitbox_sprite;see if hitbox renders first
	beq :+
		jsr buildHitbox
	:
	jsr OAM_buildBullets

	jsr OAM_buildPlayer
	
	jsr OAM_buildEffects
	
	jsr OAM_buildPowerups
	bcs @oamFull

	jsr buildEnemies
	bcs @oamFull
	
	jsr buildPlayerBullets
	bcs @oamFull

	jsr OAM_clearRemaining

@oamFull:

	rts


buildHitbox:;x(x,a)

	clc
	lda Hitbox_yPos
	sta buildY

	lda Hitbox_xPos
	sta buildX

	lda Hitbox_sprite

	jmp OAM_build; void(a)

.proc OAM_buildBullets
LIMIT=32

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

.align 32
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
		
		sec
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


.align 32
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

	lda #0
	sta buildPalette

	lda Player_sprite
	jmp OAM_build; void(x) |


.proc OAM_buildEffects;		c() | 
	
	clc
	lda effectsShuffle;		each pass shuffle through collection
	adc #((EFFECTS_MAX/7)*3) | %1;	make this odd
	cmp #EFFECTS_MAX-3;		make sure no overflow
	bcc :+
		sbc #(EFFECTS_MAX-3) & %11111110;		divide even
		cmp #EFFECTS_MAX-3;	check within range	
		bcc :+;			if not within range
			sbc #(EFFECTS_MAX-3) & %11111110;	divide
	:;				endif
	sta effectsShuffle;		save new iterator
	tax
	jsr firstPass;			void(x)
	lda effectsShuffle;		get iterator
	and #%1;			see if odd
	ora #EFFECTS_MAX-2;		get the end of collection
	tax;				second loop
	jsr secondPass;		void(x)
	rts


firstPass:;					for each effect in effects
	
	lda Effects_active,x;		if active
	beq @next;			else next

		lda #00;		zero out palette
		sta buildPalette	

		lda Effects_yPos,x;	copy y coordinate
		sta buildY
		lda Effects_xPos,x;	copy x coordinate
		sta buildX
		lda Effects_sprite,x;	get the sprite
		stx xReg;		save x register
		jsr OAM_build;		c(a) |
		bcs @full;		return full
		ldx xReg;		restore x register

@next:
	dex;			next item
	dex;			next item

	bpl firstPass;		while items in collection
	sec;			return no overflow
@full:
	rts;			return c


secondPass:;		void(x)
; x - iterator	
	
	lda Effects_active,x;		if active
	beq @next;			else next

		lda #00;		zero out palette
		sta buildPalette	

		lda Effects_yPos,x;	copy y coordinate
		sta buildY
		lda Effects_xPos,x;	copy x coordinate
		sta buildX
		lda Effects_sprite,x;	get the sprite
		stx xReg;		save x register
		jsr OAM_build;		c(a) |
		bcs @full;		return full
		ldx xReg;		restore x register

@next:
	dex;			next item
	dex;			next item

	cpx effectsShuffle;	while items after first pass
	bne secondPass
	sec;			return no overflow
@full:
	rts;			return c

.endproc


.proc OAM_buildPowerups;	void()
	
	ldx #POWERUPS_MAX-1;	for each item in powerups

@loop:
	lda Powerups_active,x;	if active
	beq @next
		tay;			active byte is also ID
		lda Powerups_yPos,x;	copy y value
		sta buildY
		lda Powerups_xPos,x;	copy x value
		sta buildX
		
		lda #0
		sta buildPalette;	clear out palette
		
		stx xReg;		save x
		lda Powerups_sprite,y;	get sprite
		jsr OAM_build;		c(a) | 
		bcs @full;		return c set if full
		ldx xReg;		recall x
@next:
	dex;		while powerups remain
	bpl @loop
	clc;		mark not full
@full:
	rts;		c
.endProc


buildPlayerBullets:

	lda #0
	sta buildPalette

	ldy #SHOTS_MAX-1

@loop:
	lda Shots_isActive,y
	beq @skip

		lda bulletY,y
		sta buildY
		lda bulletX,y
		sta buildX
		lda bulletSprite,y

		sty yReg
		jsr OAM_build; void(a)
		bcs @full
		ldy yReg

@skip:	

	dey
	bpl @loop
	clc
	rts

@full:
	sec
	rts


.proc buildEnemies
LIMIT = 8
	
	lda #LIMIT; set sprite limit for layer
	sta limit
	
	lda enemyShuffle; shuffle bullets
	adc #(MAX_ENEMIES/7) * 5; 3/5ths item collection
	cmp #MAX_ENEMIES-1; use carry instead of -2
	bcc @storeShuffle
		sbc #MAX_ENEMIES-1; make sure no wrap
@storeShuffle:
	sta enemyShuffle

	tay; set as initial iterator
	
@firstPass:
	lda isEnemyActive,y
	beq @skipEnemy
		
		dec limit
		bmi @full

		lda enemyYH,y
		sta buildY
		lda enemyXH,y
		sta buildX
		lda enemyPalette,y
		sta buildPalette
		
		sty yReg

		lda enemyMetasprite,y
		jsr OAM_build; void(a)
		bcs @oamFull
		ldy yReg

@skipEnemy:

	dey
	bpl @firstPass


	ldy #MAX_ENEMIES-1

@secondPass:
	lda isEnemyActive,y
	beq @skip
		
		dec limit
		bmi @full

		lda enemyYH,y
		sta buildY
		lda enemyXH,y
		sta buildX
		lda enemyPalette,y
		sta buildPalette
		
		sty yReg

		lda enemyMetasprite,y
		jsr OAM_build; void(a)
		bcs @oamFull
		
		ldy yReg

@skip:

	dey
	cpy enemyShuffle
	bne @secondPass

@full:	
	clc
@oamFull:
	rts; c

.endproc


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
OAM_build:;	c(a)  | 
; a - metasprite to build
; c - set if full
	
	tax

	lda Sprites_l,x
	sta spritePointer
	lda Sprites_h,x
	sta spritePointer+1
	
	ldy #0; sprite 0
	
	ldx OAM_index; get the index

@spriteLoop:

	lda (spritePointer),y
	beq @finished

		sta OAM+OFFSET_TILE,x
		iny
		
		clc
		lda buildY
		eor #$80
		adc (spritePointer),y
		eor #$80
		bvs @nextAtY
		sta OAM+OFFSET_Y,x
		iny

		clc
		lda buildX
		eor #$80
		adc (spritePointer),y
		eor #$80
		bvs @nextAtX
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

		beq @full
		
		jmp @spriteLoop
	@nextAtY:
		iny
	@nextAtX:
		iny
		iny
		jmp @spriteLoop
@finished:

	stx OAM_index
	
	clc
	rts

@full:
	sec
	rts


OAM_clearRemaining:
;arguments
;x-starting point to clear
	
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
