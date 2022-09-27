.include "enemies.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "shots.h"
.include "bullets.h"
.include "pickups.h"
.include "score.h"
.include "apu.h"
.include "ppu.h"
.include "patterns.h"

.zeropage
totalDamage: .res 1

Enemies_ptr: .res 2

.data
MAX_ENEMIES = 16
isEnemyActive: .res MAX_ENEMIES
Enemies_ID: .res MAX_ENEMIES
enemyXH: .res MAX_ENEMIES
enemyXL: .res MAX_ENEMIES
enemyYH: .res MAX_ENEMIES
enemyYL: .res MAX_ENEMIES
enemyHPH: .res MAX_ENEMIES
enemyHPL: .res MAX_ENEMIES
enemyMetasprite: .res MAX_ENEMIES
Enemies_diameter: .res MAX_ENEMIES
enemyPalette: .res MAX_ENEMIES
Enemies_pattern:.res MAX_ENEMIES
Enemies_index:.res MAX_ENEMIES
Enemies_movement:.res MAX_ENEMIES
Enemies_vulnerability:.res MAX_ENEMIES
Enemies_clock:.res MAX_ENEMIES

i:.res MAX_ENEMIES
j:.res MAX_ENEMIES

.code
Enemies_new:; void(a)
;places enemy from slot onto enemy array and screen coordinates
;arguments
;a - enemy
	
	tay

	jsr Enemies_get; x() | y
	bcc @enemiesFull
	
		tya; retrieve ID 
		sta Enemies_ID,x
		
		lda romEnemyHPH,y
		sta enemyHPH,x
		lda romEnemyHPL,y
		sta enemyHPL,x

		lda diameter,y
		sta Enemies_diameter,x
		
		lda #00
		sta Enemies_index,x
		sta Enemies_clock,x
		sta i,x
		sta j,x

		lda #TRUE

		sta isEnemyActive,x
		;sec; return true

@enemiesFull:
	;clc; return false
	rts

Enemies_get:; x() | y
;returns
;x - enemy offset

	ldx #MAX_ENEMIES-1; for each enemy
@enemySlotLoop:

	lda isEnemyActive,x; if active
	beq @returnEnemy

		dex; next enemy
		bpl @enemySlotLoop; while x
		clc; return false
		rts

@returnEnemy:; else return active
	sec; return true
	rts


Enemies_tick:
;arguments - none
;returns - none

	ldx #MAX_ENEMIES-1; for each enemy
@loop:

	lda isEnemyActive,x;update active enemies
	beq @nextEnemy

		sec
		sbc #1
		sta isEnemyActive,x
		bne @statePersists

			jsr Enemies_tickState		

	@statePersists:

		jsr Enemies_move; void(x) |  if cleared
		bcc :+
			lda #FALSE; remove from collection
			sta isEnemyActive,x
			jmp @nextEnemy
		:

		lda Enemies_vulnerability,x; if vulnerable
		beq :+
		jsr Enemies_isAlive; a(x) |  and defeated
		bcs :+

			lda #FALSE; remove from collection
			sta isEnemyActive,x
			jmp @nextEnemy
		:
		jsr Patterns_tick; void(x)
		inc Enemies_clock,x

@nextEnemy:
	dex
	bpl @loop; while x
	
	rts


Enemies_tickState:
			
	ldy Enemies_ID,x; get format string
	lda Enemies_L,y
	sta Enemies_ptr+0
	lda Enemies_H,y
	sta Enemies_ptr+1

	lda Enemies_index,x; retrieve index
	tay

	lda (Enemies_ptr),y; get movement
	bne :+; null terminated
		iny
		lda (Enemies_ptr),y; next byte is repeat-at
		tay; new index
		lda (Enemies_ptr),y; get movement
	:
	sta Enemies_movement,x
	iny
	
	lda (Enemies_ptr),y; get metasprite
	sta enemyMetasprite,x
	iny

	lda (Enemies_ptr),y; get pattern
	jsr Patterns_new; void(a) | x,y
	iny

	lda (Enemies_ptr),y; get vulnerability
	sta Enemies_vulnerability,x
	iny

	lda (Enemies_ptr),y; get vulnerability
	sta isEnemyActive,x
	iny

	tya
	sta Enemies_index,x

	lda #0
	sta Enemies_clock,x

	rts


Enemies_move:

	ldy Enemies_movement,x; if null
	beq @return

		lda Movement_L,y
		sta Enemies_ptr+0
		lda Movement_H,y
		sta Enemies_ptr+1

		jmp (Enemies_ptr); void Enemies_move  c(x) | x

@return:
	clc	
	rts


Enemies_isAlive:; c(x) |
;compares enemies to the player bullets and determines if they overlap
;arguments
;x - enemy to check'
;y - player bullet

	lda #0
	sta totalDamage;clear out damage
	sta enemyPalette,x; set palette to default
	ldy #SHOTS_MAX-1
@bulletLoop:
;find an active bullet
	lda Shots_isActive,y
	beq @nextBullet

		sec; find x distance
		lda bulletY,y
		sbc enemyYH,x
		bcs :+
		
			eor #%11111111; if negative
		
		:cmp Enemies_diameter,x; if distance < diameter
		bcs @nextBullet
	
		sec; find y distance
		lda bulletX,y
		sbc enemyXH,x
		bcs :+
	
			eor #%11111111
		
		:cmp Enemies_diameter,x
		bcs @nextBullet

			;clc; total damage
			lda PlayerBullet_damage,y
			adc totalDamage
			sta totalDamage

			lda #%11
			sta enemyPalette,x

			lda #FALSE
			sta Shots_isActive,y

@nextBullet:
	dey
	bpl @bulletLoop
	
	sec
	lda enemyHPL,x
	sbc totalDamage
	sta enemyHPL,x
	lda enemyHPH,x
	sbc #0
	sta enemyHPH,x

	rts; c

Enemies_transferPoints:	

	;lda Enemies_pointValue_L,x
	;adc Score_frameTotal_L
	;sta Score_frameTotal_L
	;lda Enemies_pointValue_H,x
	;adc Score_frameTotal_H
	;sta Score_frameTotal_H
	;bcs @error

ENEMY01=1; Reese Boss
ENEMY02=2; Blue Drone down light right
ENEMY03=3
ENEMY04=4
ENEMY05=5
ENEMY06=6
ENEMY07=7
ENEMY08=$8
.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot

romEnemyHPL: 
	.byte 	NULL,	100,	10,	10
romEnemyHPH:
	.byte 	NULL,	00,	00,	10
pointValue_L:
	.byte 	NULL,	19,	10,	10
pointValue_H:
	.byte 	NULL,	00,	00,	00
diameter:
	.byte 	NULL,	16,	12,	08


SIZE		= 5; bytes
VULNERABLE	= TRUE
INVULNERABLE	= FALSE

Enemy01:
	.byte MOVEMENT01
	.byte SPRITE18
	.byte PATTERN02
	.byte VULNERABLE
	.byte 255; frames


Enemy02:
	.byte MOVEMENT04
	.byte SPRITE0F; move onscreen
	.byte NULL
	.byte VULNERABLE
	.byte 16; frames

	.byte MOVEMENT02
	.byte SPRITE0F; stop and shoot
	.byte PATTERN02
	.byte VULNERABLE
	.byte 128; frames

	.byte MOVEMENT03
	.byte SPRITE0F; move off
	.byte NULL
	.byte VULNERABLE
	.byte 255; frames

Enemy03:


Enemies_L:
	.byte NULL,<Enemy01,<Enemy02,<Enemy03
Enemies_H:
	.byte NULL,>Enemy01,>Enemy02,>Enemy03


MOVEMENT01=$01; reese boss not moving
MOVEMENT02=$02; down to soft right
MOVEMENT03=$03; down to medium right
MOVEMENT04=$04; ease down


;Enemy stays in place
.proc Movement01; c(x) |
	clc
	rts
.endproc

;moves enemy with y scroll
.proc Movement02; c(x) |
	
	clc
	lda enemyYL,x
	adc PPU_scrollSpeed_l
	sta enemyYL,x
	lda enemyYH,x
	adc PPU_scrollSpeed_h
	sta enemyYH,x
	rts

.endproc

.proc Movement03; c(x) |
SPEED_Y=2
MUTATOR=16
	
	clc
	lda i,x
	adc #MUTATOR
	sta i,x
	lda j,x
	adc #0
	sta j,x

	lda enemyXL,x
	adc i,x
	sta enemyXL,x
	lda enemyXH,x
	adc j,x
	sta enemyXH,x
	bcs @return
	
	lda enemyYH,x
	adc #SPEED_Y
	sta enemyYH,x
@return:
	rts; c
	

.endproc

.proc Movement04
	
	lda Enemies_clock,x
	asl
	asl
	and #%011
	tay
	clc
	lda enemyYH,x
	adc Ease00,y
	sta enemyYH,x

	rts; c

.endproc


Ease00:
	.byte 2, 2, 2, 1
	

Movement_L:
	.byte NULL,<Movement01,<Movement02,<Movement03,<Movement04
Movement_H:
	.byte NULL,>Movement01,>Movement02,>Movement03,>Movement04
