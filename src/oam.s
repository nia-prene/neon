.include "lib.h"

.include "oam.h"

.include "sprites.h"
.include "score.h"
.include "player.h"
.include "playerbullets.h"
.include "enemies.h"
.include "bullets.h"

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
OAM_overflowFrames: .res 1
OAM_hideExcessSprites: .res 1
.segment "OAM"
oam: .res 256

.code
OAM_build:;c (c)
;builds oam 
;call with carry set to exclude player
;returns carry clear if oam overflow
	inc o ;module iterator
	ldx #0
	bcs @buildWithoutPlayer
;build hitbox if button a is being pressed
	and #%10000000
	beq :+
		jsr buildHitbox
:	jsr buildEnemyBullets
	bcs @oamFull
	jsr buildPlayer
	bcs @oamFull
	jsr buildEnemies
	bcs @oamFull
;if there arent enough sprites, stop building scoreboard
	lda OAM_hideExcessSprites
	bne :+
		jsr OAM_buildScore
		bcs @oamFull
:	jsr buildPlayerBullets
	bcs @oamFull
;if there arent enough sprites, stop building hearts
	lda OAM_hideExcessSprites
	bne :+
		jsr buildHearts
		bcs @oamFull
:	jsr clearRemaining
	jmp @allSPritesRendered
@buildWithoutPlayer:
	jsr buildEnemyBullets
	bcs @oamFull
	jsr buildEnemies
	bcs @oamFull
;if there arent enough sprites, stop building scoreboard
	lda OAM_hideExcessSprites
	bne :+
		jsr OAM_buildScore
		bcs @oamFull
:	jsr buildPlayerBullets
	bcs @oamFull
;if there arent enough sprites, stop building hearts
	lda OAM_hideExcessSprites
	bne :+
		jsr buildHearts
		bcs @oamFull
:	jsr clearRemaining
@allSPritesRendered:
	sec
	lda OAM_overflowFrames
	sbc #1
	bpl :+
		lda #0
:	sta OAM_overflowFrames
	lda #FALSE
	sta OAM_hideExcessSprites
	rts
@oamFull:
	clc
	lda OAM_overflowFrames
	adc #1
	cmp #MAX_OVERFLOW_FRAMES+1
	bcc :+
		lda #MAX_OVERFLOW_FRAMES
		lda #TRUE
		sta OAM_hideExcessSprites
:	sta OAM_overflowFrames
	rts

buildHitbox:
PLAYER_HITBOX_Y_OFFSET=5
	lda #NULL;terminate
	pha
	lda o
	and #%00001000
	lsr
	lsr
	lsr
	tay
	lda @hitboxAnimation,y
	pha
	clc
	lda playerY_H
	adc #PLAYER_HITBOX_Y_OFFSET
	pha
	lda playerX_H
	pha
	lda #00
	pha
	jmp buildSpritesShort
@hitboxAnimation:
	.byte SPRITE06, SPRITE07

buildEnemyBullets:
	lda #NULL;terminate
	pha
	ldy #MAX_ENEMY_BULLETS-1
@enemyBulletLoop:
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
	bpl @enemyBulletLoop
	jmp buildSpritesShort

buildPlayer:
;prepares player sprite for oam
;first push a null to terminate 
;then push sprite, y, x, palette
	lda #NULL;terminator
	pha
	lda playerSprite
	pha
	lda playerY_H
	pha
	lda playerX_H
	pha
	lda #0;palette implied
	pha
	jmp buildSprites

buildPlayerBullets:
	lda #NULL;terminate
	pha
	lda o
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
	lda #NULL
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

buildHearts:
	lda #NULL;null terminated
	pha
	lda playerHP
	and #%00000111
	tay
@heartLoop:
	lda #HEART_SPRITE
	pha
	lda #220; y value
	pha
	lda heartX,y
	pha
	lda #0;palette
	pha
	dey
	bpl @heartLoop
	jmp buildSpritesShort
heartX:;location of hearts
	.byte 10, 18, 26, 34, 42, 50, 58

OAM_buildScore:
	lda #NULL
	pha
	ldy #6
@loop:
	lda Score_displaySprites,y
	pha
	lda #8
	pha
	lda Score_xPositions,y
	pha
	lda #00
	pha
	dey
	bpl @loop
	jmp buildSpritesShort

buildSprites:
;builds collections of sprites
;push tile, y, x, palette
;pull and use in reverse order
;returns
;x - current OAM position
	pla
	cmp #NULL
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
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		ora buildPalette
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		adc buildX
		bcs @xOverflow
	@returnX:
		sta oam,x
		inx
		beq @oamFull
		iny
		lda (spritePointer),y
		cmp #NULL
		bne @tileLoop
	pla
	cmp #NULL
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
	cmp #NULL
	beq @returnFull
	pla ;x
	pla ;y
	pla ;sprite
	jmp @oamFull
@returnFull:
	sec ;set full
	rts

buildSpritesShort:
;builds collections of sprites
;push tile, y, x, palette
;pull and use in reverse order
;returns
;x - current OAM position

;if first byte = null, no sprites
	pla
	cmp #NULL
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
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		adc buildX
		bcs @xOverflow
	@returnX:
		sta oam,x
		inx
		beq @oamFull
		iny
		lda (spritePointer),y
		cmp #NULL
		bne @tileLoop
	pla
	cmp #NULL
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
	cmp #NULL
	beq @returnFull
	pla ;x
	pla ;y
	pla ;sprite
	jmp @oamFull
@returnFull:
	sec
	rts

clearRemaining:
;arguments
;x-starting point to clear
	lda #$ff
@clearOAM:
	sta oam,x
	inx
	inx
	inx
	sta oam,x
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
