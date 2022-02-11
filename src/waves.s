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
w: .res 1 ;iterator that counts frames and decides when to place enemies
ENEMY_FREQUENCY=%00001111 ;how often should a new enemy be dispensed
CONCURRENT=$FE ;signals that two enemies are to be dispensed this frame
SKIP=0
.code
Waves_reset:;void(x)
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
	sta enemyIndex
	sta waveIndex
	sta w
	rts

dispenseEnemies:
	inc w
	lda w
	and #ENEMY_FREQUENCY
	bne @return
	;track the index in the array
	ldy enemyIndex
	;if y=0, get a new wave
	beq @newWave
@addAnother:
	;else get the enemy
	lda (wavePointer),y
	;zero marks a skip
	beq @skip
	;null terminated
	cmp #TERMINATE
	beq @hold
	;save enemy
	pha
	iny
	;get the encoded coordinate bit (see table below)
	lda (wavePointer),y
	;save new index position
	iny
	sty enemyIndex
	;get the x and y coordinate using the look up table
	tax
	lda waveY,x
	pha
	lda waveX,x
	tax
	pla
	tay
	pla
	jsr initializeEnemy;(a,x,y)
	ldy enemyIndex
	lda (wavePointer),y
	iny
	cmp #CONCURRENT
	beq @addAnother
@return:
	rts
@skip:
	iny
	sty enemyIndex
	rts
@hold:
	jsr areEnemiesRemaining
	bcc @noneRemaining
	rts
@noneRemaining:
	lda #0
	sta enemyIndex
	rts
@newWave:
	ldy waveIndex
	lda (levelWavePointer),y
	tax
	lda wavePointerL,x
	sta wavePointer
	lda wavePointerH,x
	sta wavePointer+1
	iny
	sty waveIndex
	ldy enemyIndex
	;get the bullets
	lda (wavePointer),y
	sta bulletType
	sta bulletType+2
	iny
	lda (wavePointer),y
	sta bulletType+1
	iny
	lda (wavePointer),y
	sta bulletType+3
;get the palettes
	iny
	lda (wavePointer),y
	pha
	iny
	lda (wavePointer),y
	pha
	iny
	sty enemyIndex
	jmp Palettes_swapEnemyPalettes

areEnemiesRemaining:
	ldx #MAX_ENEMIES-1
@enemyLoop:
	lda isEnemyActive,x
	bne @enemiesActive
	dex
	bpl @enemyLoop
	clc
	rts
@enemiesActive:
	sec
	rts
	
.rodata
;waves for each level as index to pointers
WAVESTRING00=0
waveStrings_H:
	.byte >waveString00
waveStrings_L:
	.byte <waveString00
waveString00:
	.byte WAVE00, WAVE01, WAVE02, WAVE03, WAVE04, WAVE03, WAVE06, WAVE05, WAVE07
;pointers to individual enemy waves (below)

WAVE00=$00;Ready? Go!
WAVE01=$01;ligh drones moving left
WAVE02=$02;ligh drones moving right
WAVE03=$03;medium drones moving left
WAVE04=$04;left baloon with light right moving drones
WAVE05=$05
WAVE06=$06
WAVE07=$07;piper boss fight

wavePointerH:
	.byte >wave00, >wave01, >wave02, >wave03, >wave04, >wave05, >wave06, >wave07
wavePointerL:
	.byte <wave00, <wave01, <wave02, <wave03, <wave04, <wave05, <wave06, <wave07

;individual enemy waves
;	.byte PALETTE, PALETTE
;	.byte bulletType, bulletType, bulletType
;	.byte enemy, position, (skip), enemy, position ... TERMINATE
wave00:
	.byte 0, 0, 0
	.byte PALETTE00, PALETTE00 
	.byte 6, 62, SKIP, SKIP, SKIP, SKIP, SKIP, 7, 62, TERMINATE
wave01:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 2, 14, SKIP, 2, 16, SKIP, 2, 18, SKIP, 2, 20, SKIP, 2, 22, TERMINATE
wave02:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 1, 18, SKIP, 1, 16, SKIP, 1, 14, SKIP, 1, 12, SKIP, 1, 10, TERMINATE
wave03:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 2, 12, 2, 14, 2, 16, 2, 18, 2, 20, 2, 22, TERMINATE
wave04:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 3, 70, 1, 16, SKIP, 1, 14, SKIP, 1, 12, SKIP, 1, 10, SKIP, 1, 08, TERMINATE
wave05:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 1, 20, 1, 18, 1, 16, 1, 14, 1, 12, 1, 10, TERMINATE

wave06:
	.byte 0, 1, 1
	.byte PALETTE06, PALETTE06 
	.byte 5, 24, SKIP, SKIP, SKIP, SKIP, SKIP, SKIP, SKIP, SKIP, SKIP, SKIP, 1, 16, 1, 15, 1, 14, TERMINATE
wave07:
	.byte 0, 1, 1
	.byte PALETTE08, PALETTE09 
	.byte 8, 24, TERMINATE
;Coordinate Table
;x and y coordinate decoder table for enemy spawn locations
waveX:
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
waveY:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $04, $0c, $14, $1c, $24, $2c, $34, $3c, $44, $4c, $54, $5c, $64, $6c, $74, $7c
	.byte $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $c4, $cc, $d4, $dc, $e4, $ec, $f4, $fc
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff



