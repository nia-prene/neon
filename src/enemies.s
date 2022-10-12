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

MAX_ENEMIES = 16
.zeropage
totalDamage: .res 1

isEnemyActive: .res MAX_ENEMIES

.data
enemyYH: .res MAX_ENEMIES
enemyXH: .res MAX_ENEMIES
Enemies_ID: .res MAX_ENEMIES
enemyXL: .res MAX_ENEMIES
enemyYL: .res MAX_ENEMIES
enemyHPH: .res MAX_ENEMIES
enemyHPL: .res MAX_ENEMIES
enemyMetasprite: .res MAX_ENEMIES
Enemies_diameter: .res MAX_ENEMIES
enemyPalette: .res MAX_ENEMIES
Enemies_pattern:.res MAX_ENEMIES
Enemies_animation:.res MAX_ENEMIES
Enemies_animationIndex:.res MAX_ENEMIES
Enemies_animationTimer:.res MAX_ENEMIES
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

		dec isEnemyActive,x
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
		dec Enemies_animationTimer,x
		bne :+
			jsr Enemies_tickAnimation
		:
		jsr Patterns_tick; void(x)
		inc Enemies_clock,x

@nextEnemy:
	dex
	bpl @loop; while x
	
	rts


Enemies_tickState:
			
	ldy Enemies_ID,x; get ID
	
	lda Enemies_L,y; get state pointer
	sta Lib_ptr0+0
	lda Enemies_H,y
	sta Lib_ptr0+1

	ldy Enemies_index,x; retrieve index

	lda (Lib_ptr0),y; get movement
	bne :+; null terminated
		iny
		lda (Lib_ptr0),y; next byte is repeat-at
		tay; new index
		lda (Lib_ptr0),y; get movement
	:
	sta Enemies_movement,x
	iny
	
	lda (Lib_ptr0),y; get animation
	sta Enemies_animation,x
	iny

	lda (Lib_ptr0),y; get pattern
	jsr Patterns_new; void(a) | x,y
	iny

	lda (Lib_ptr0),y; get vulnerability
	sta Enemies_vulnerability,x
	iny

	lda (Lib_ptr0),y; get state timer
	sta isEnemyActive,x
	dec isEnemyActive,x; this frame counts
	iny

	tya
	sta Enemies_index,x

	lda #0
	sta Enemies_clock,x
	sta Enemies_animationIndex,x

	jmp Enemies_tickAnimation


Enemies_move:

	ldy Enemies_movement,x; if null
	beq @return

		lda Movement_L,y
		sta Lib_ptr0+0
		lda Movement_H,y
		sta Lib_ptr0+1

		jmp (Lib_ptr0); void Enemies_move  c(x) | x

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


Enemies_tickAnimation:

	ldy Enemies_animation,x; if animation is null
	bne :+
		lda #NULL; Clear Metasprite
		sta enemyMetasprite,x
		lda #255; Max out timer
		sta Enemies_animationTimer,x
		rts
	:
	lda Animations_l,y; get the animation
	sta Lib_ptr1+0
	lda Animations_h,y
	sta Lib_ptr1+1

	ldy Enemies_animationIndex,x; get index into animation
	lda (Lib_ptr1),y
	bne :+; Null terminated
		iny
		lda (Lib_ptr1),y; loop here
		tay
		lda (Lib_ptr1),y; get the metasprite
	:
	sta enemyMetasprite,x
	iny

	lda (Lib_ptr1),y; get frame count for animation
	sta Enemies_animationTimer,x
	iny
	
	tya
	sta Enemies_animationIndex,x; save index
	
	rts


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
ENEMY04=$04; Balloon cannon left!
ENEMY05=$05; fairy going left and right
ENEMY06=$06
ENEMY07=$07
ENEMY08=$08
.rodata
;first byte is a burner byte so we can use zero flag to denote empty slot

romEnemyHPL: 
	.byte 	NULL,	$00,	$10,	$18,	$00
	.byte 	$30
romEnemyHPH:
	.byte 	NULL,	$00,	$00,	$00,	$01
	.byte 	$00
pointValue_L:
	.byte 	NULL,	$19,	$10,	$10,	$30
	.byte 	$20
pointValue_H:
	.byte 	NULL,	$00,	$00,	$00,	$00
	.byte 	$00
diameter:
	.byte 	NULL,	16,	$10,	08,	$10
	.byte 	$10


SIZE		= 5; bytes
VULNERABLE	= TRUE
INVULNERABLE	= FALSE

Enemy01:
	.byte MOVEMENT01
	.byte ANIMATION01
	.byte PATTERN02
	.byte VULNERABLE
	.byte 255; frames


Enemy02:
	.byte MOVEMENT04
	.byte ANIMATION01; move onscreen
	.byte NULL
	.byte VULNERABLE
	.byte 32; frames

	.byte MOVEMENT01
	.byte ANIMATION01; stop and shoot
	.byte PATTERN02
	.byte VULNERABLE
	.byte 128; frames

	.byte MOVEMENT05
	.byte ANIMATION01; move off
	.byte NULL
	.byte VULNERABLE
	.byte 255; frames

Enemy03:
	.byte MOVEMENT02; stand, crouch
	.byte ANIMATION02
	.byte NULL
	.byte VULNERABLE
	.byte 32

	.byte MOVEMENT06; jump and shoot
	.byte ANIMATION03
	.byte PATTERN03
	.byte VULNERABLE
	.byte 32
	.byte NULL, 00; stop and loop


Enemy04:
	.byte MOVEMENT02
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT01
	.byte ANIMATION04
	.byte PATTERN04
	.byte VULNERABLE
	.byte 128
	.byte MOVEMENT01
	.byte ANIMATION04
	.byte PATTERN04
	.byte VULNERABLE
	.byte 128
	.byte MOVEMENT01
	.byte ANIMATION04
	.byte PATTERN04
	.byte VULNERABLE
	.byte 128
	.byte MOVEMENT03
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 255


Enemy05:

	.byte MOVEMENT07
	.byte ANIMATION01
	.byte PATTERN03
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT08
	.byte ANIMATION01
	.byte PATTERN03
	.byte VULNERABLE
	.byte 64

	.byte NULL, 0

Enemies_L:
	.byte NULL,<Enemy01,<Enemy02,<Enemy03
	.byte <Enemy04,<Enemy05
Enemies_H:
	.byte NULL,>Enemy01,>Enemy02,>Enemy03
	.byte >Enemy04,>Enemy05


MOVEMENT01=$01; not moving
MOVEMENT02=$02; gravity
MOVEMENT03=$03; ballon drift left
MOVEMENT04=$04; ease in - down with gravity 32 frames
MOVEMENT05=$05; ease out - up with gravity 32 frames
MOVEMENT06=$06; jump down (mushroom)
MOVEMENT07=$07; glide left (fairy)
MOVEMENT08=$08; glide right (fairy)


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
MUTATOR=1
	
	clc
	lda i,x
	adc #MUTATOR
	sta i,x
	lda j,x
	adc #0
	sta j,x
	
	sec
	lda enemyXL,x
	sbc i,x
	sta enemyXL,x
	lda enemyXH,x
	sbc j,x
	sta enemyXH,x
	bcs :+
		sec
		rts; c
	:
	clc	
	lda enemyYH,x
	adc Scroll_delta
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


.proc Movement07
SPEED=1
	lda Enemies_clock,x
	lsr
	lsr
	lsr
	tay

	sec
	lda enemyXL,x
	sbc Ease_in_l,y
	sta enemyXL,x

	lda enemyXH,x
	sbc Ease_in_h,y
	sta enemyXH,x
	
	clc
	lda enemyYH,x
	adc #SPEED
	sta enemyYH,x
	
	rts; c

.endproc


.proc Movement08
SPEED=1

	lda Enemies_clock,x
	lsr
	lsr
	lsr
	tay

	clc
	lda enemyXL,x
	adc Ease_in_l,y
	sta enemyXL,x

	lda enemyXH,x
	adc Ease_in_h,y
	sta enemyXH,x
	
	clc
	lda enemyYH,x
	adc #SPEED
	sta enemyYH,x
	
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
	.byte 	     NULL,<Movement01,<Movement02,<Movement03
	.byte <Movement04,<Movement05,<Movement06,<Movement07
	.byte <Movement08
Movement_H:
	.byte        NULL,>Movement01,>Movement02,>Movement03
	.byte >Movement04,>Movement05,>Movement06,>Movement07
	.byte >Movement08
