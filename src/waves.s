.include "lib.h"

.include "waves.h"

.include "enemies.h"
.include "bullets.h"

.zeropage
levelWavePointer: .res 2 ;points to the collection of waves for the level
wavePointer: .res 2 ;points to the current wave in use
waveIndex: .res 1 ;keeps track of current wave in the collection
enemyIndex: .res 1 ;keeps track of which enemy is next
w: .res 1 ;iterator that counts frames and decides when to place enemies
ENEMY_FREQUENCY=%00011111 ;how often should a new enemy be dispensed
CONCURRENT=$FE ;signals that two enemies are to be dispensed this frame

.code

Waves_reset:;void(x)
;sets up the level's enemy wave system
;arguments
;x - current scene
	;get the pointer to the collection of waves for the current level
	lda levelWavesL,x
	sta levelWavePointer
	lda levelWavesH,x
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
	cmp #NULL
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
	iny
	sty enemyIndex
	rts

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
BEACH=0
levelWavesH:
	.byte >beachWaves
levelWavesL:
	.byte <beachWaves
;waves for each level as index to pointers
beachWaves:
	.byte 0, 1, 2, 3, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
;pointers to individual enemy waves (below)
wavePointerH:
	.byte >wave00, >wave01, >wave02, >wave03, >wave04
wavePointerL:
	.byte <wave00, <wave01, <wave02, <wave03, <wave04

;individual enemy waves
;	.byte bulletType, bulletType, bulletType
;	.byte enemy, position, (skip), enemy, position ... NULL
wave00:
	.byte 0, 1, 1
	.byte 2, 17, 2, 24, 2, 18, 2, 26, 2, 20, 2, 28, 2, 23, NULL
wave01:
	.byte 0, 1, 1
	.byte 1, 18, 1, 10, 1, 15, 1, 7, 1, 13, 1, 2, 1, 4, NULL
wave02:
	.byte 0, 1, 1
	.byte 3, 70,  2, 12, 2, 16, 2, 21, 2, 25, 2, 21, 2, 17, 2, 13, 2, 9, NULL
wave03:
	.byte 0, 1, 1
	.byte 2, 23, 1, 8, 2, 25, 1, 6, 2, 21, 1, 10, 2, 23, 1, 8, 2, 25, 1, 6, 2, 21, 1, 10, 2, 23, 1, 8, NULL
wave04:
	.byte 0, 1, 1
	.byte 5, 35, NULL


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



