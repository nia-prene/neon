.include "lib.h"
.include "powerup.h"

.zeropage
Powerup_y: .res 1
Powerup_x: .res 1
Powerup_isActive: .res 1

.code
Powerup_dispense:
	lda Powerup_isActive
	bne @return
	pla
	sta Powerup_y
	pla 
	sta Powerup_x
	lda #TRUE
	sta Powerup_isActive
@return:
	pla
	pla
	rts

Powerup_move:
	lda Powerup_isActive
	bne @active
	rts
@active:
	clc
	lda Powerup_y
	adc #1
	sta Powerup_y
	rts

isCollected:
	sbc Powerup_x
	bcs @playerGreaterX
	eor #%11111111
@playerGreaterX:
	cmp #16
	bcs @return

	sbc Powerup_y
	bcs @playerGreaterY
	eor #%11111111
@playerGreaterY:
	cmp #32
	bcs @return

@return:
	rts
