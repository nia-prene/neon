.include "enemies.h"

.include "lib.h"

.include "player.h"
.include "sprites.h"
.include "shots.h"
.include "bullets.h"
.include "pickups.h"
.include "score.h"
.include "apu.h"
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
		
		lda #TRUE
		sta isEnemyActive,x
		lda #00
		sta Enemies_index,x
		;sec; return true
		rts

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
		;sta isEnemyActive,x
		bne @statePersists

			jsr Enemies_tickState		

	@statePersists:

		jsr Enemies_move; void(x) |

		lda Enemies_vulnerability,x
		beq @alive

			jsr Enemies_isAlive; a(x) |
			bcs @alive
			
	@alive:
		

@nextEnemy:

	dex
	bpl @loop; while x
	
	rts


Enemies_tickState:
			
	ldy Enemies_ID,x; get format string
	lda Enemies_string_L,y
	sta Enemies_ptr+0
	lda Enemies_string_H,y
	sta Enemies_ptr+1

	ldy Enemies_index,x; retrieve index

	lda (Enemies_ptr),y; get metasprite
	sta enemyMetasprite,x
	iny

	lda (Enemies_ptr),y; get movement
	sta Enemies_movement,x
	iny
	
	lda (Enemies_ptr),y; get pattern
	jsr Patterns_new; void(a) | x,y
	iny

	lda (Enemies_ptr),y; get vulnerability
	sta Enemies_vulnerability,x
	iny

	lda (Enemies_ptr),y; get vulnerability
	sta isEnemyActive,x
	tya
	sta Enemies_index,x

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
	
	clc
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

Enemies_explodeSmall:
	pla
	tax
;lasts for 16 frames
	;lda i,x
	cmp #16
	bcs @clear
;divide by 4 to find animation frame
	lsr
	lsr
	tay
	lda @animationFrames,y
	sta enemyMetasprite,x
	;inc i,x
	rts
@clear:
	;lda j,x
	bne @dropPowerup
	lda #FALSE
	sta isEnemyActive,x
;pickup algo here
	rts
@dropPowerup:
	lda #<(Pickups_movePowerup-1)
	;sta enemyBehaviorL,x
	lda #>Pickups_movePowerup
	;sta enemyBehaviorH,x
	rts
@animationFrames:
	.byte SPRITE0A, SPRITE0B ,SPRITE0C ,SPRITE0D


.macro explode	size, powerUp
	lda #0
	sta enemyPalette,x
	sta i,x
	lda powerUp
	sta j,x
.if (.xmatch ({size}, 0))
	lda #<(Enemies_explodeSmall-1)
	sta enemyBehaviorL,x
	lda #>Enemies_explodeSmall
	sta enemyBehaviorH,x
.else 
	.error "explosion needs size"
.endif
	lda #1
	jsr SFX_newEffect
	rts
.endmacro
ENEMY01=1; Reese Boss
ENEMY02=2
ENEMY03=3
ENEMY04=4
ENEMY05=5
ENEMY06=6;Ready?
ENEMY07=7;Go!
ENEMY08=$8;reese boss
.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot

romEnemyHPL: 
	.byte NULL, 02
romEnemyHPH:
	.byte NULL, 00
pointValue_L:
	.byte NULL, $19
pointValue_H:
	.byte NULL, 00

diameter:
	.byte NULL, 16

Enemies_string_L:
	.byte NULL, <String01
Enemies_string_H:
	.byte NULL, >String01

VULNERABLE=TRUE
INVULNERABLE=FALSE

String01:
	.byte SPRITE18
	.byte MOVEMENT01
	.byte PATTERN01
	.byte VULNERABLE
	.byte 255; frames


Enemies_move:

	ldy Enemies_movement,x

	lda Movement_L,y
	sta Enemies_ptr+0
	lda Movement_H,y
	sta Enemies_ptr+1

	jmp (Enemies_ptr); void Enemies_move(x) | x


MOVEMENT01=$01
Movement_L:
	.byte NULL, <Movement01


Movement_H:
	.byte NULL, >Movement01

.proc Movement01
X_OFFSET=116
Y_OFFSET=32
	
	lda #X_OFFSET; set x
	sta enemyXH,x
	lda #Y_OFFSET; set x
	sta enemyYH,x
	
	rts
.endproc
