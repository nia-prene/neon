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

ENEMY01=$01; Reese Boss
ENEMY02=$02; Blue Drone down light right
ENEMY03=$03; Mushroom hopper
ENEMY04=$04
ENEMY05=$05
ENEMY06=$06
ENEMY07=$07
ENEMY08=$08
.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot

romEnemyHPL: 
	.byte 	NULL,	$00,	$10,	$18,	$20
romEnemyHPH:
	.byte 	NULL,	$00,	$00,	$00,	$00
pointValue_L:
	.byte 	NULL,	$19,	$10,	$10,	$30
pointValue_H:
	.byte 	NULL,	$00,	$00,	$00,	$00
diameter:
	.byte 	NULL,	16,	12,	08,	$10


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
	.byte 32; frames

	.byte MOVEMENT01
	.byte SPRITE0F; stop and shoot
	.byte PATTERN02
	.byte VULNERABLE
	.byte 128; frames

	.byte MOVEMENT05
	.byte SPRITE0F; move off
	.byte NULL
	.byte VULNERABLE
	.byte 255; frames

Enemy03:
	.byte MOVEMENT02
	.byte SPRITE23
	.byte NULL
	.byte VULNERABLE
	.byte 8
	.byte MOVEMENT02
	.byte SPRITE24
	.byte NULL
	.byte VULNERABLE
	.byte 8
	.byte MOVEMENT06
	.byte SPRITE25
	.byte PATTERN03
	.byte VULNERABLE
	.byte 16

	.byte NULL, 00; stop and loop


Enemies_L:
	.byte NULL,<Enemy01,<Enemy02,<Enemy03
Enemies_H:
	.byte NULL,>Enemy01,>Enemy02,>Enemy03


MOVEMENT01=$01; not moving
MOVEMENT02=$02; gravity
MOVEMENT03=$03; down to medium right
MOVEMENT04=$04; ease in - down with gravity 32 frames
MOVEMENT05=$05; ease out - up with gravity 32 frames
MOVEMENT06=$06; move down linearly (mushroom)


;Enemy stays in place
.proc Movement01; c(x) |
	clc
	rts
.endproc

;moves enemy with y scroll
.proc Movement02; c(x) |
	
	clc
	lda enemyYH,x
	adc Scroll_delta
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
	cmp #%11111
	bcc :+
		lda #%11111
	:
	lsr
	tay
	clc
	lda enemyYL,x
	adc Ease_out_l,y
	sta enemyYL,x
	lda enemyYH,x
	adc Ease_out_h,y
	sta enemyYH,x

	rts; c

.endproc


.proc Movement05
	
	lda Enemies_clock,x
	cmp #%11111
	bcc :+
		lda #%11111
	:
	lsr
	tay
	sec
	lda enemyYL,x
	sbc Ease_in_l,y
	sta enemyYL,x
	lda enemyYH,x
	sbc Ease_in_h,y
	sta enemyYH,x
	bcs :+
		sec; clear from screen
		rts; c
	:
	clc
	
	rts; c

.endproc


.proc Movement06
SPEED_h=1
SPEED_l=0
	
	clc
	lda enemyYH,x
	adc #SPEED_h
	bcs :+
	adc Scroll_delta
	sta enemyYH,x
	:
	rts; c

.endproc


Ease_in_l:
	.byte 0, 0, 0, 0, 16, 16, 32, 48, 80, 112, 144, 208, 0, 80, 160, 0
Ease_in_h:
	.byte  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  2
	
Ease_out_l:
	.byte 0,0,0,0,240, 240, 224, 208, 176, 144, 112, 48, 0, 176, 96, 0
Ease_out_h:
	.byte  2,  2,  2,  2,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0

Movement_L:
	.byte NULL,<Movement01,<Movement02,<Movement03,<Movement04
	.byte <Movement05,<Movement06
Movement_H:
	.byte NULL,>Movement01,>Movement02,>Movement03,>Movement04
	.byte >Movement05,>Movement06
