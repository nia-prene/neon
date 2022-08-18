.include "lib.h"

.include "waves.h"

.include "enemies.h"
.include "scenes.h"
.include "bullets.h"
.include "palettes.h"

.zeropage
levelWavePointer: .res 2 ;points to the collection of waves for the level
wavePointer: .res 2 ;points to the current wave in use
waveIndex: .res 1 ;keeps track of current wave in the collection
enemyIndex: .res 1 ;keeps track of which enemy is next
w: .res 1 

Waves_hold:.res 1; hold for x frames



CONCURRENT=$FE ;signals that two enemies are to be dispensed this frame
SKIP=0
.code
Waves_new:;void(x)
;sets up the level's enemy wave system
;arguments
;x - current scene
;get the string index from the scene
	lda Scenes_waveString,x
	tax

	lda waveStrings_L,x
	sta levelWavePointer
	lda waveStrings_H,x
	sta levelWavePointer+1
	;start on 0th wave, 0th enemy
	lda #0
	sta waveIndex

	jmp Waves_next; void()


dispenseEnemies:
	
	clc
	lda Waves_hold
	sbc #1
	bcc @dispenseEnemy
		
		sta Waves_hold; return if timer >= 0
		rts

@dispenseEnemy:

	ldy enemyIndex; recall index

	lda (wavePointer),y; if null (to terminate) new wave
	bne @addAnother
		
		jmp Waves_next

@addAnother:

	iny
	sty enemyIndex	

	jsr initializeEnemy; x(a) |
	
	ldy enemyIndex
	bcc @enemiesFull
	
	lda (wavePointer),y; get position on screen
	
	iny
	sty enemyIndex

	rol
	rol
	rol
	pha
	and #%11
	tay
	pla
	ror
	and #%11111100
	pha

	lda @sides_H,y; get the function pointer
	pha
	lda @sides_L,y
	pha

	rts; void(x) | x
@enemiesFull:

	iny
	iny
	sty enemyIndex

@setTime:
	
	ldy enemyIndex; recall index

	lda (wavePointer),y; if zero time, make immediate enemy
	beq @addAnother

	sta Waves_hold
	
	iny
	sty enemyIndex
	
	sec; mark success
	rts

@sides_L:
	.byte <(@top-1),<(@right-1),<(@bottom-1),<(@left-1)
@sides_H:
	.byte >(@top-1),>(@right-1),>(@bottom-1),>(@left-1)
@top:; void(a,x) | x,y
	pla
	sta enemyXH,x
	lda #0
	sta enemyYH,x
	jmp @setTime
@right:; void(a,x) | x,y
	pla
	sta enemyYH,x
	lda #0
	sta enemyXH,x
	jmp @setTime

@bottom:; void(a,x) | x,y
	pla
	sta enemyXH,x
	lda #255
	sta enemyYH,x
	jmp @setTime

@left:; void(a,x) | x,y
	pla
	sta enemyYH,x
	lda #0
	sta enemyXH,x
	jmp @setTime

Waves_next:

	ldy waveIndex; recall index
	lda (levelWavePointer),y; get next wave
	beq @bossTime

	iny
	sty waveIndex
	
	pha; save wave

	tax; get the pointer
	lda wavePointerL,x
	sta wavePointer
	lda wavePointerH,x
	sta wavePointer+1



	lda Wave_palette00,x
	tax
	ldy #5
	jsr setPalette; void(x,y)
	
	pla
	lda Wave_palette01,x
	tax
	ldy #6
	jsr setPalette; void(x,y)
	
	lda #0
	sta enemyIndex

	sec; mark success
	rts

@bossTime:

	clc; mark end
	rts


.rodata
;waves for each level as index to pointers
WAVESTRING00=0
waveStrings_H:
	.byte >waveString00
waveStrings_L:
	.byte <waveString00
waveString00:
	.byte WAVE01,WAVE01,WAVE01,WAVE01
	.byte WAVE01,WAVE01,WAVE01,WAVE01
	.byte NULL
;pointers to individual enemy waves (below)

WAVE01=$01;ligh drones moving left
WAVE02=$02;ligh drones moving right
WAVE03=$03;medium drones moving left
WAVE04=$04;left baloon with light right moving drones
WAVE05=$05
WAVE06=$06
WAVE07=$07;piper boss fight


TOP=%00
RIGHT=%01
BOTTOM=%10
LEFT=%11

Wave_palette00:
	.byte PALETTE06
Wave_palette01:
	.byte PALETTE06

;individual enemy waves
;	.byte enemy, position, hold, etc, NULL

wave01:
	
	.byte ENEMY01, TOP|32, 10
	.byte ENEMY01, TOP|30, 10
	.byte ENEMY01, TOP|28, 10
	.byte ENEMY01, TOP|26, 10
	.byte ENEMY01, TOP|24, 10
	.byte ENEMY01, TOP|22, 255
	.byte NULL

wave02:
wave03:
wave04:
wave05:
wave06:
wave07:


wavePointerH:
	.byte NULL,>wave01,>wave02,>wave03,>wave04,>wave05,>wave06,>wave07
wavePointerL:
	.byte NULL,<wave01,<wave02,<wave03,<wave04,<wave05,<wave06,<wave07
