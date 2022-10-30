.include "gamepads.h"

JOY1 = $4016;Joystick 1 data (R) and joystick strobe (W)
JOY2 = $4017;Joystick 2 data (R) and frame counter control (W) 
.zeropage
Gamepads_state: .res 1
Gamepads_last: .res 1

.code
Gamepads_read:;a(x)
CHECKS=2;	number of times we will read controllers for accuracy
	lda Gamepads_state
	sta Gamepads_last

	ldx #0

@redoRead:
	ldy #CHECKS-1
@readPads:
	lda #$01
	pha
	sta JOY1;write 1 then 0 to latch gamepad state
    lsr ;now A is 0
    sta JOY1
@loop:
    lda JOY1,x
    and #%00000011  ; ignore bits other than controller
    cmp #$01        ; Set carry if and only if nonzero
	pla
	rol ; Carry -> bit 0; bit 7 -> Carry
	pha
    bcc @loop
	dey;first read is on stack
	bpl @readPads;do second
	pla;pull second read
	sta Gamepads_state
	pla;pull first read
	cmp Gamepads_state
	bne @redoRead;redo if different
    rts
