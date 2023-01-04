.include "enemies.h"

.include "lib.h"

.include "apu.h"
.include "bullets.h"
.include "effects.h"
.include "patterns.h"
.include "powerups.h"
.include "player.h"
.include "ppu.h"
.include "score.h"
.include "shots.h"
.include "sprites.h"

MAX_ENEMIES 	= 16
CHILDREN_MAX 	= 8
.zeropage
totalDamage: 			.res 1
isEnemyActive: 			.res MAX_ENEMIES

enemyYH:			.res MAX_ENEMIES
enemyXH: 			.res MAX_ENEMIES

.data
Enemies_ID: 		.res MAX_ENEMIES
enemyXL: 		.res MAX_ENEMIES
enemyYL: 		.res MAX_ENEMIES
enemyHPH: 		.res MAX_ENEMIES
enemyHPL: 		.res MAX_ENEMIES
enemyMetasprite: 	.res MAX_ENEMIES
Enemies_diameter: 	.res MAX_ENEMIES
enemyPalette: 		.res MAX_ENEMIES
Enemies_pattern:	.res MAX_ENEMIES
Enemies_animation:	.res MAX_ENEMIES
Enemies_animationIndex:	.res MAX_ENEMIES
Enemies_animationTimer:	.res MAX_ENEMIES
Enemies_index:		.res MAX_ENEMIES
Enemies_movement:	.res MAX_ENEMIES
Enemies_vulnerability:	.res MAX_ENEMIES
Enemies_clock:		.res MAX_ENEMIES
Enemies_fuse:		.res MAX_ENEMIES
i:			.res MAX_ENEMIES
j:			.res MAX_ENEMIES

Children_active:	.res CHILDREN_MAX
Children_offset:	.res CHILDREN_MAX

Enemies_allTriggers:		.res 1;			gamestate triggers

.code
Enemies_new:; void(a)
;places enemy from slot onto enemy array and screen coordinates
;arguments
;a - enemy
	tax

	jsr Enemies_get; x() | y
	bcc @enemiesFull
	
		txa; retrieve ID 
		sta Enemies_ID,y
		
		lda romEnemyHPH,x
		sta enemyHPH,y
		lda romEnemyHPL,x
		sta enemyHPL,y

		lda diameter,x
		sta Enemies_diameter,y
		
		lda #00
		sta Enemies_index,y
		sta Enemies_clock,y
		sta Enemies_fuse,y
		sta i,y
		sta j,y
		sta enemyMetasprite,y

		lda #TRUE
		sta isEnemyActive,y
		;sec; return true

@enemiesFull:
	;clc; return false
	rts


Children_new:;			c,y(a) | x
; a - child enemy ID
	
	stx xReg;		save parent

	tax;			get child ID

	jsr Enemies_get;	x() | y		get empty enemy
	bcc @enemiesFull;	if enemy available
	
		txa; 			set ID 
		sta Enemies_ID,y
		
		lda romEnemyHPH,x;	set HP
		sta enemyHPH,y
		lda romEnemyHPL,x
		sta enemyHPL,y

		lda diameter,x;		set hitbox
		sta Enemies_diameter,y
		
		lda #00;		zero out attributes
		sta Enemies_index,y
		sta Enemies_clock,y
		sta Enemies_fuse,y
		sta enemyMetasprite,y
		sta j,y


		jsr Children_get;	c,x() | y
		bcc @enemiesFull;	return if full
		
		tya;			save the offset
		sta Children_offset,x
		
		lda #TRUE
		sta Children_active,x;	set active

		ldx xReg;		restore parent
		lda enemyYH,x;		copy parent y
		sta enemyYH,y
		lda enemyXH,x;		copy parent x
		sta enemyXH,y
		txa
		sta i,y;		save parent
		
		lda #TRUE;		set active
		sta isEnemyActive,y
		
		;sec; return true

@enemiesFull:
	;clc; return false
	rts


Enemies_newSpawn:;	c(a,x)
;a - enemy
;x - parent enemy
	
	pha

	jsr Enemies_get; 	y() | x
	pla; 			retrieve ID 
	bcc @enemiesFull;	return if full
		sta Enemies_ID,y;	store ID
		
		lda enemyYH,x;		copy y coordinates
		sta enemyYH,y

		lda enemyXH,x;		copy y coordinates
		sta enemyXH,y
		
		ldx Enemies_ID,y;	get the ID

		lda romEnemyHPH,x
		sta enemyHPH,y
		lda romEnemyHPL,x
		sta enemyHPL,y

		lda diameter,x
		sta Enemies_diameter,y
		
		lda #00
		sta Enemies_index,y
		sta Enemies_clock,y
		sta Enemies_fuse,y
		sta enemyMetasprite,y
		sta i,y
		sta j,y

		lda #TRUE
		sta isEnemyActive,y
		;sec; return true

@enemiesFull:
	;clc; return false
	rts


Enemies_get:; y() | x
;returns
;y - enemy offset

	ldy #MAX_ENEMIES-1; for each enemy
@enemySlotLoop:

	lda isEnemyActive,y; if active
	beq @returnEnemy
		dey; next enemy
		bpl @enemySlotLoop; while x
		clc; return false
		rts
@returnEnemy:; else return active
	sec; return true
	rts


Children_get:;			c,y() | x
	ldx #CHILDREN_MAX-1;	for each child
@loop:	
	lda Children_active,x;	if inactive
	beq @return;		else return child
		dex;		tick down through collection
		bpl @loop
		clc;		mark fail
		rts;		c
@return:
	sec;			mark success
	rts;			c


Enemies_tick:;			a() |	
; a - bit encoded triggers
	
	lda #FALSE;		clear gamestate triggers
	sta Enemies_allTriggers

	ldx #MAX_ENEMIES-1; 	for each enemy
@loop:

	lda isEnemyActive,x;update active enemies
	beq @nextEnemy

		dec isEnemyActive,x;	tick down state timer
		bne :+;			if timer is 0
			jsr Enemies_tickState;	next state
		:;			endif
		jsr Enemies_move; void(x) |  if cleared
		bcc :+
			lda #FALSE; remove from collection
			sta isEnemyActive,x
			jmp @nextEnemy
		:
		lda Enemies_fuse,x;	if enemy has fuse
		beq @alive;		endif
			dec Enemies_fuse,x;	tick down fuse
			bne @nextEnemy;		if 0 else next
				ldy Enemies_ID,x;	get ID
				lda Enemies_powerups,y;	get powerup byte
				beq :+;			if nonzero
					jsr Powerups_new;	void(a,x) | x
				:
				lda #FALSE;		clear
				sta isEnemyActive,x
				jmp @nextEnemy;		next enemy
	@alive:;					endif
		lda Enemies_animationTimer,x
		bne :+
			jsr Enemies_tickAnimation
		:
		dec Enemies_animationTimer,x;	tick timer down

		lda Enemies_vulnerability,x; 	if vulnerable
		beq :+
		jsr Enemies_isAlive; 		a(x) |  and defeated
		bcs :+
			jsr Enemies_defeat;	a(x) | 	
			jsr Enemies_transferPoints
			jmp @nextEnemy;		next in collection
		:
		jsr Patterns_tick; void(x)
@nextEnemy:

	inc Enemies_clock,x;	tick clock
	
	dex
	bpl @loop; 		while x
	
	lda Enemies_allTriggers
	rts;			return a


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
	sta Enemies_animationTimer,x

	rts


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
			lda PlayerBullet_damage,y;	tally the damage
			adc totalDamage
			sta totalDamage

			lda #%11;			set palette to flash
			sta enemyPalette,x

			stx xReg;			save enemy
			tya;				put shot on x
			tax
			jsr Effects_get;		y() | x
			bcc :+;				if effect available
				lda bulletY,x;		copy y
				sta Effects_yPos,y
				lda bulletX,x;		copy x
				sta Effects_xPos,y
				lda #ANIMATION07;	add animation
				sta Effects_animation,y

				lda #0;			zero out frame
				sta Effects_frame,y
				lda #TRUE;		set active
				sta Effects_active,y
			:;			endif
			txa;			put shot on y
			tay
			ldx xReg;		restore enemy

			lda #FALSE;		deactivate shot	
			sta Shots_isActive,y

@nextBullet:
	dey;			step through collection
	bpl @bulletLoop;	while positive
	
	sec
	lda enemyHPL,x
	sbc totalDamage
	sta enemyHPL,x
	lda enemyHPH,x
	sbc #0
	sta enemyHPH,x

	rts; c


Enemies_defeat:;		void(x) | x
FUSE 	= 16
	
	ldy Enemies_ID,x;		get ID
	
	lda Enemy_fuse,y;		set fuse
	sta Enemies_fuse,x
	
	lda #MOVEMENT02;		set movement
	sta Enemies_movement,x

	lda #255;			don't allow state change
	sta isEnemyActive,x

	lda #00;			clear out the palette
	sta enemyPalette,x
	
	stx xReg;			save x
	sty yReg;			save y
	lda #SFX01;			make sound effect
	jsr SFX_newEffect
	ldx xReg;			restore x
	ldy yReg;			restore y

	lda Enemies_trigger,y;		add to list of triggers
	ora Enemies_allTriggers
	sta Enemies_allTriggers
	
	lda Enemies_spawn,y;		if going to spawn enemy
	beq :+
		sty yReg;		save registers
		stx xReg
		jsr Enemies_newSpawn;		c(a) |	make a spawn enemy
		ldx xReg
		ldy yReg
	:
	lda Enemies_effect,y;		get the defeat effect
	beq :+
		jmp Enemies_newEffect;		void(a) | x
	:
	rts



Children_clear:;		void() | x
	stx xReg;		save x register
	
	ldy #CHILDREN_MAX-1;	for each child
@loop:
	lda Children_active,y;	if active
	beq @next;		else next
		ldx Children_offset,y
		lda #FALSE;		deactivate
		sta isEnemyActive,x
		sta Children_active,y
@next:
	dey;			while children left
	bpl @loop

	ldx xReg;		restore x register
	rts


Enemies_newEffect:;		void(a) | x
; a - animation

	pha;			save effect
	jsr Effects_get; 	get an available effect c,y() | x
	pla;			retrieve effect
	bcc @return;		no open effect

		sta Effects_animation,y;	effect is animation

		lda enemyYH,x;			copy x from enemy
		sta Effects_yPos,y
		lda enemyXH,x;			copy y from enemy
		sta Effects_xPos,y

		lda #0;				zero out animation frame
		sta Effects_frame,y

		lda #TRUE;			set as active
		sta Effects_active,y
@return:
	rts


Enemies_tickAnimation:; void(x) | x

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


Enemies_transferPoints:;	void(x) | x
; x - enemy	
	clc
	ldy Enemies_ID,x
	lda Enemies_points_l,y
	adc Score_frameTotal_L
	sta Score_frameTotal_L
	
	lda Enemies_points_h,y
	adc Score_frameTotal_H
	sta Score_frameTotal_H

	rts

ENEMY01		= $01;	reese boss phase 1
ENEMY02		= $02;	fairy that returns fast
ENEMY03		= $03;	mushroom hopper
ENEMY04		= $04;	balloon cannon left
ENEMY05		= $05;	balloon cannon right
ENEMY06		= $06;	fairy that return slow
ENEMY07		= $07;	reese's left handgun
ENEMY08		= $08;	reese's right handgun
ENEMY09		= $09;	reese's left pattern
ENEMY0A		= $0A;	reese's right pattern
ENEMY0B		= $0B;	reese's left sniper
ENEMY0C		= $0C;	reese's right sniper
ENEMY0D		= $0D;	reese boss phase 2

.rodata


romEnemyHPL:;	total hit points until defeat
	.byte 	NULL,	$01,	$20,	$30	
	.byte 	$80, 	$80,	$10,	$00
	.byte	$00,	$00,	$00,	$00
	.byte 	$00,	$00
romEnemyHPH:
	.byte 	NULL,	$00,	$00,	$00
	.byte	$00,	$00,	$00,	$FF
	.byte	$FF,	$FF,	$FF,	$FF
	.byte	$00,	$08
Enemies_points_l:;	points gained on defeat
	.byte 	NULL,	$00,	$10,	$10
	.byte	$30,	$20,	$10,	$00
	.byte	$00,	$00,	$00,	$00
	.byte	$00,	$00
Enemies_points_h:
	.byte 	NULL,	$10,	$00,	$00
	.byte	$00,	$00,	$00,	$00
	.byte	$00,	$00,	$00,	$00
	.byte	$00,	$10

diameter:;	hitbox diameter
	.byte 	NULL,	$10,	$10,	$10
	.byte	$10,	$10,	$10,	$00
	.byte	$00,	$00,	$00,	$00
	.byte	$00,	$10

Enemies_powerups:;	powerup byte |b b b s s s s s|
	.byte	NULL,	0|0, 	0|0, 	0|1
	.byte	0|3, 	0|3, 	0|0,	$00
	.byte	$00,	$00,	$00,	$00
	.byte	$00,	$00
Enemy_fuse:
	.byte	NULL,	$01,	$10,	$10
	.byte	$10,	$10,	$10,	$10
	.byte	$10,	$10,	$10,	$10
	.byte	$10,	$10
Enemies_effect:
	.byte 	NULL
	.byte	ANIMATION09
	.byte	ANIMATION06
	.byte	ANIMATION06
	.byte	ANIMATION06
	.byte	ANIMATION06
	.byte	ANIMATION06
	.byte	ANIMATION06

	.byte	NULL
	.byte	NULL
	.byte	NULL
	.byte	NULL
	.byte	NULL
	.byte	ANIMATION09


Enemies_spawn:
	.byte NULL
	.byte ENEMY0D
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL

	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL


.proc Enemies_trigger
WIN	=	%1
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL

	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte NULL
	.byte WIN
.endproc


SIZE		= 5; bytes
VULNERABLE	= TRUE
INVULNERABLE	= FALSE

Enemy01:
	.byte MOVEMENT0A;	fly up
	.byte ANIMATION09
	.byte NULL
	.byte VULNERABLE
	.byte 64+8; frames
	
	.byte MOVEMENT0E;	spawn handguns
	.byte ANIMATION09
	.byte NULL
	.byte VULNERABLE
	.byte 255; frames

	.byte MOVEMENT0B;	spawn patterns
	.byte ANIMATION09
	.byte NULL
	.byte VULNERABLE
	.byte 255

	.byte MOVEMENT08;	charge forward
	.byte ANIMATION09
	.byte PATTERN06
	.byte VULNERABLE
	.byte 16

	.byte MOVEMENT11;	pull back handgun
	.byte ANIMATION09
	.byte PATTERN07
	.byte VULNERABLE
	.byte 93;		lign up with previous value

	.byte MOVEMENT12;	spawn snipers and self pattern
	.byte ANIMATION0A
	.byte PATTERN08
	.byte VULNERABLE
	.byte 255; frames

	.byte NULL, 2*SIZE


Enemy02:
	.byte MOVEMENT09
	.byte ANIMATION01; move onscreen
	.byte NULL
	.byte VULNERABLE
	.byte 32; frames

	.byte MOVEMENT02
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

	.byte MOVEMENT06; jump 
	.byte ANIMATION03
	.byte NULL
	.byte VULNERABLE
	.byte 08
	
	.byte MOVEMENT02; stand, crouch
	.byte ANIMATION02
	.byte NULL
	.byte VULNERABLE
	.byte 32

	.byte MOVEMENT06; jump 
	.byte ANIMATION03
	.byte NULL
	.byte VULNERABLE
	.byte 32

	.byte MOVEMENT02; stand, shoot
	.byte ANIMATION05
	.byte PATTERN03
	.byte VULNERABLE
	.byte 255
	
	.byte MOVEMENT02; stand, crouch
	.byte ANIMATION02
	.byte NULL
	.byte VULNERABLE
	.byte 32

	.byte MOVEMENT06; jump 
	.byte ANIMATION03
	.byte NULL
	.byte VULNERABLE
	.byte 32

	.byte NULL,(SIZE*4); stop and loop


Enemy04:; balloon exit left
	.byte MOVEMENT02; 	float down
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT02;	float and shoot
	.byte ANIMATION04
	.byte PATTERN04
	.byte VULNERABLE
	.byte 255
	.byte MOVEMENT02; 	float down
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT03;	exit
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 255


Enemy05:; balloon cannon exit right
	.byte MOVEMENT02; 	float down
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT02;	stop and shoot
	.byte ANIMATION04
	.byte PATTERN04
	.byte VULNERABLE
	.byte 255
	.byte MOVEMENT02; 	float down
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 64
	.byte MOVEMENT07;	exit right
	.byte ANIMATION04
	.byte NULL
	.byte VULNERABLE
	.byte 255


Enemy06:

	.byte MOVEMENT09
	.byte ANIMATION01; move onscreen
	.byte NULL
	.byte VULNERABLE
	.byte 32; frames

	.byte MOVEMENT02
	.byte ANIMATION01; stop and shoot
	.byte PATTERN02
	.byte VULNERABLE
	.byte 255; frames

	.byte MOVEMENT05
	.byte ANIMATION01; move off
	.byte NULL
	.byte VULNERABLE
	.byte 255; frames

Enemy07:
	.byte MOVEMENT0C;	shoot handgun
	.byte NULL
	.byte PATTERN05
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0


Enemy08:
	.byte MOVEMENT0D;	shot handgun
	.byte NULL
	.byte PATTERN05
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0


Enemy09:
	.byte MOVEMENT0F;	make pattern on left
	.byte NULL
	.byte PATTERN01
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0


Enemy0A:
	.byte MOVEMENT10;	make pattern on right
	.byte NULL
	.byte PATTERN01
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0

Enemy0B:
	.byte MOVEMENT0C;	make sniper on left
	.byte NULL
	.byte PATTERN05
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0

Enemy0C:
	.byte MOVEMENT0D;	make sniper on right
	.byte NULL
	.byte PATTERN05
	.byte INVULNERABLE
	.byte 255
	.byte NULL, 0


Enemy0D:
	.byte MOVEMENT01;	stand still
	.byte NULL;		be invisible
	.byte NULL;		don't shoot
	.byte INVULNERABLE;	don't take tamage
	.byte 255;		wait for flicker to stop	

	.byte MOVEMENT13;	ease back to center
	.byte ANIMATION09;	floating animation
	.byte NULL;		don't shoot
	.byte VULNERABLE;	don't take tamage
	.byte $80
	
	.byte MOVEMENT14;	ease in right
	.byte ANIMATION09;	floating animation
	.byte NULL;		don't shoot
	.byte VULNERABLE;	don't take tamage
	.byte 64
	
	.byte MOVEMENT15;	ease out right
	.byte ANIMATION09;	floating animation
	.byte NULL;		don't shoot
	.byte VULNERABLE;	don't take tamage
	.byte 16
	
	.byte MOVEMENT16;	ease in left
	.byte ANIMATION09;	floating animation
	.byte PATTERN09;	shoot forward
	.byte VULNERABLE;	don't take tamage
	.byte 128
	
	.byte MOVEMENT17;	ease out left
	.byte ANIMATION09;	floating animation
	.byte NULL;		don't shoot
	.byte VULNERABLE;	don't take tamage
	.byte 16
	
	.byte MOVEMENT14;	ease in right
	.byte ANIMATION09;	floating animation
	.byte PATTERN09;	shoot forward
	.byte VULNERABLE;	don't take tamage
	.byte 128
	
	.byte MOVEMENT15;	ease out right
	.byte ANIMATION09;	floating animation
	.byte NULL;		don't shoot
	.byte VULNERABLE;	don't take tamage
	.byte 16
	
	.byte NULL,(SIZE*4)


Enemies_L:
	.byte NULL,<Enemy01,<Enemy02,<Enemy03
	.byte <Enemy04,<Enemy05,<Enemy06,<Enemy07
	.byte <Enemy08,<Enemy09,<Enemy0A,<Enemy0B
	.byte <Enemy0C,<Enemy0D
Enemies_H:
	.byte NULL,>Enemy01,>Enemy02,>Enemy03
	.byte >Enemy04,>Enemy05,>Enemy06,>Enemy07
	.byte >Enemy08,>Enemy09,>Enemy0A,>Enemy0B
	.byte >Enemy0C,>Enemy0D


MOVEMENT01=$01; not moving
MOVEMENT02=$02; gravity
MOVEMENT03=$03; exit left (balloon)
MOVEMENT04=$04; ease in - down 32 frames
MOVEMENT05=$05; ease out - up with gravity 32 frames
MOVEMENT06=$06; jump down (mushroom)
MOVEMENT07=$07; exit right (baloon
MOVEMENT08=$08; reese charge forward
MOVEMENT09=$09; ease in - down 64 frames
MOVEMENT0A=$0A; ease in - up 64 frames (reese boss)
MOVEMENT0B=$0B; spawn reese's side patterns
MOVEMENT0C=$0C; lock $20 pixels left of parent
MOVEMENT0D=$0D; lock $20 pixels right of parent
MOVEMENT0E=$0E; spawn reese's handguns
MOVEMENT0F=$0F; Lock $60 pixels left of parent
MOVEMENT10=$10; Lock $60 pixels right of parent
MOVEMENT11=$11; reese charge back
MOVEMENT12=$12; spawn reese's snipers
MOVEMENT13	= $13;		move back to boss center
MOVEMENT14	= $14;		ease in right
MOVEMENT15	= $15;		ease out right
MOVEMENT16	= $16;		ease in left
MOVEMENT17	= $17;		ease out left
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
	adc Ease_outTwos_l,y
	sta enemyYL,x
	lda enemyYH,x
	adc Ease_outTwos_h,y
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
	sbc Ease_inTwos_l,y
	sta enemyYL,x
	lda enemyYH,x
	sbc Ease_inTwos_h,y
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
MUTATOR=1
	
	clc
	lda i,x
	adc #MUTATOR
	sta i,x
	lda j,x
	adc #0
	sta j,x
	
	clc
	lda enemyXL,x
	adc i,x
	sta enemyXL,x

	lda enemyXH,x
	adc j,x
	sta enemyXH,x
	bcs @return
	
	lda enemyYH,x
	adc Scroll_delta
	sta enemyYH,x
@return:
	rts; c
	

.endproc


.proc Movement08
	
	ldy Enemies_clock,x
	bne :+
		jsr Children_clear;	void() | x
		ldy Enemies_clock,x
	:
	
	clc
	lda Ease_outFours_l,y
	adc enemyYL,x
	sta enemyYL,x

	lda Ease_outFours_h,y
	adc enemyYH,x
	sta enemyYH,x

	rts

.endproc


.proc Movement09
	lda Enemies_clock,x
	cmp #%111111
	bcc :+
		lda #%11111
	:
	lsr
	lsr
	tay
	clc
	lda enemyYL,x
	adc Ease_outTwos_l,y
	sta enemyYL,x
	lda enemyYH,x
	adc Ease_outTwos_h,y
	sta enemyYH,x

	rts; c
.endproc


.proc Movement0A
	sec
	lda enemyYH,x
	sbc #3
	sta enemyYH,x

	clc
	rts

.endproc


.proc Movement0B

	lda Enemies_clock,x;	poke clock
	bne :+;			if 0th frame
		lda #ENEMY09;		make left pattern
		jsr Children_new;	c,y(x) | x
		lda #ENEMY0A;		make right pattern
		jsr Children_new;	c,y(x) | x
	:
	clc;			mark still onscreen
	rts;			c

.endproc


.proc Movement0C;	c(x) | x
DISTANCE	= $18
	
	ldy i,x;	get parent
	lda enemyYH,y;	set y
	sta enemyYH,x
	
	sec
	lda enemyXH,y;	move left N pixels
	sbc #DISTANCE
	sta enemyXH,x;	set x
	
	clc;			mark false
	lda isEnemyActive,y;	if parent is inactive
	bne :+
		sec;		mark true
	:
	rts;			c

.endproc


.proc Movement0D;	c(x) | x
DISTANCE	= $18
	
	ldy i,x;	get parent
	lda enemyYH,y;	set y
	sta enemyYH,x
	
	clc
	lda enemyXH,y;	move right N pixels
	adc #DISTANCE
	sta enemyXH,x;	set x
	
	clc;			mark false
	lda isEnemyActive,y;	if parent is inactive
	bne :+
		sec;		mark true
	:
	rts;			c

.endproc


.proc Movement0E
	lda Enemies_clock,x;	poke clock
	bne :+;			if 0th frame
		lda #ENEMY07;		make left handgun
		jsr Children_new;	c,y(x) | x
		lda #ENEMY08;		make left handgun
		jsr Children_new;	c,y(x) | x
	:
	clc;			mark still onscreen
	rts;			c

.endproc


.proc Movement0F
DISTANCE	= $60
	
	ldy i,x;	get parent
	lda enemyYH,y;	set y
	sta enemyYH,x
	
	sec
	lda enemyXH,y;	move right N pixels
	sbc #DISTANCE
	sta enemyXH,x;	set x
	
	clc;			mark false
	lda isEnemyActive,y;	if parent is inactive
	bne :+
		sec;		mark true
	:
	rts;			c


.endproc


.proc Movement10
DISTANCE	= $60
	
	ldy i,x;	get parent
	lda enemyYH,y;	set y
	sta enemyYH,x
	
	clc
	lda enemyXH,y;	move right N pixels
	adc #DISTANCE
	sta enemyXH,x;	set x
	
	clc;			mark false
	lda isEnemyActive,y;	if parent is inactive
	bne :+
		sec;		mark true
	:
	rts;			c

.endproc

.proc Movement11
SPEED		= $0080
	
	lda Enemies_clock,x
	bne :+
		lda #00;	zero this out so same spot
		sta enemyYL,x
	:
	sec
	lda enemyYL,x
	sbc #<SPEED
	sta enemyYL,x

	lda enemyYH,x
	sbc #>SPEED
	sta enemyYH,x
	
	clc
	rts

.endproc


.proc Movement12
	lda Enemies_clock,x;	poke clock
	bne :+;			if 0th frame
		lda #ENEMY0B;		make left sniper
		jsr Children_new;	c,y(x) | x
		lda #ENEMY0C;		make right sniper
		jsr Children_new;	c,y(x) | x
	:
	clc;			mark still onscreen
	rts;			c
	

.endproc

.proc Movement13
BOSS_Y 	= $30
BOSS_X 	= $80
	
	sec
	lda enemyYH,x;	find distance
	sbc #BOSS_Y
	bcs :+
		eor #%11111111;		if negative, twos compliment
		adc #1;		
		tay;			set as speed
		
		;clc
		lda enemyYL,x;		move player down
		adc Charm_speed_L,y
		sta enemyYL,x

		lda enemyYH,x
		adc Charm_speed_H,y
		sta enemyYH,x
		jmp @doX
	:
	tay;			set as speed offset
	lda enemyYL,x;		move player up
	sbc Charm_speed_L,y
	sta enemyYL,x

	lda enemyYH,x
	sbc Charm_speed_H,y
	sta enemyYH,x

@doX:
	sec
	lda enemyXH,x;	find distance
	sbc #BOSS_X
	bcs :+
		eor #%11111111;		if negative, two's compliment
		adc #1
		tay
		
		lda enemyXL,x;		move player right
		adc Charm_speed_L,y
		sta enemyXL,x

		lda enemyXH,x
		adc Charm_speed_H,y
		sta enemyXH,x
		jmp @return
	:
	tay;			set as speed offset
	lda enemyXL,x;			else move left
	sbc Charm_speed_L,y
	sta enemyXL,x

	lda enemyXH,x
	sbc Charm_speed_H,y
	sta enemyXH,x
	
@return:
	clc;			mark on-screen
	rts
.endproc

.proc Movement14
	
	ldy Enemies_clock,x
	cpy #%1111
	bcc :+
		ldy #%1111
	:
	clc
	lda enemyXL,x
	adc Ease_inOnes_l,y
	sta enemyXL,x

	lda enemyXH,x
	adc Ease_inOnes_h,y
	sta enemyXH,x

	rts;			c

.endproc

.proc Movement15
	
	ldy Enemies_clock,x
	cpy #%1111
	bcc :+
		ldy #%1111
	:
	clc
	lda enemyXL,x
	adc Ease_outOnes_l,y
	sta enemyXL,x

	lda enemyXH,x
	adc Ease_outOnes_h,y
	sta enemyXH,x

	rts;			c

.endproc

.proc Movement16
	
	ldy Enemies_clock,x
	cpy #%1111
	bcc :+
		ldy #%1111
	:
	sec
	lda enemyXL,x
	sbc Ease_inOnes_l,y
	sta enemyXL,x

	lda enemyXH,x
	sbc Ease_inOnes_h,y
	sta enemyXH,x
	
	rol
	eor #%1
	ror

	rts;			c

.endproc

.proc Movement17
	
	ldy Enemies_clock,x
	cpy #%1111
	bcc :+
		ldy #%1111
	:
	sec
	lda enemyXL,x
	sbc Ease_outOnes_l,y
	sta enemyXL,x

	lda enemyXH,x
	sbc Ease_outOnes_h,y
	sta enemyXH,x
	
	rol
	eor #%1
	ror

	rts;			c

.endproc


Ease_inOnes_l:
	.byte	$00, $00, $00, $04, $04, $08, $10, $1C
	.byte	$28, $38, $4C, $64, $84, $A8, $D0, $00

Ease_inOnes_h:
	.byte	$00 ,$00 ,$00 ,$00 ,$00 ,$00 ,$00 ,$00
	.byte	$00 ,$00 ,$00 ,$00 ,$00 ,$00 ,$00 ,$01

Ease_outOnes_l:
	.byte	$00, $00, $00, $FC, $FC, $F8, $F0, $E4
	.byte	$D8, $C8, $B4, $9C, $7C, $58, $30, $00

Ease_outOnes_h:
	.byte	$01, $01, $01, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

Ease_inTwos_l:
	.byte 0, 0, 0, 0, 16, 16, 32, 48, 80, 112, 144, 208, 0, 80, 160, 0
Ease_inTwos_h:
	.byte  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  2
Ease_inFours_l:
Ease_inFours_H:
	
Ease_outTwos_l:
	.byte 0,0,0,0,240, 240, 224, 208, 176, 144, 112, 48, 0, 176, 96, 0
Ease_outTwos_h:
	.byte  2,  2,  2,  2,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0

Ease_outFours_l:
	.byte 0, 0, 0, 240, 240, 224, 192, 144, 96, 32, 208, 112, 240, 96, 192, 0
Ease_outFours_h:
	.byte  4,  4,  4,  3,  3,  3,  3,  3,  3,  3,  2,  2,  1,  1,  0,  0

Movement_L:
	.byte 	     NULL,<Movement01,<Movement02,<Movement03
	.byte <Movement04,<Movement05,<Movement06,<Movement07
	.byte <Movement08,<Movement09,<Movement0A,<Movement0B
	.byte <Movement0C,<Movement0D,<Movement0E,<Movement0F
	.byte <Movement10,<Movement11,<Movement12,<Movement13
	.byte <Movement14,<Movement15,<Movement16,<Movement17

Movement_H:
	.byte        NULL,>Movement01,>Movement02,>Movement03
	.byte >Movement04,>Movement05,>Movement06,>Movement07
	.byte >Movement08,>Movement09,>Movement0A,>Movement0B
	.byte >Movement0C,>Movement0D,>Movement0E,>Movement0F
	.byte >Movement10,>Movement11,>Movement12,>Movement13
	.byte >Movement14,>Movement15,>Movement16,>Movement17


