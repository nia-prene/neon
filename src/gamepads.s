.include "gamepads.h"

JOY1 = $4016;Joystick 1 data (R) and joystick strobe (W)
JOY2 = $4017;Joystick 2 data (R) and frame counter control (W) 
.zeropage
Gamepads_state: .res 2

.code
Gamepads_read:
;read only during VBLANK
	lda #$01
	sta Gamepads_state+1; player 2's buttons double as a ring counter
	sta JOY1;write 1 then 0 to latch gamepad state
    lsr          ; now A is 0
    sta JOY1
loop:
    lda JOY1
    and #%00000011  ; ignore bits other than controller
    cmp #$01        ; Set carry if and only if nonzero
	rol Gamepads_state; Carry -> bit 0; bit 7 -> Carry
    lda JOY2     ; Repeat
    and #%00000011
    cmp #$01
	rol Gamepads_state+1; Carry -> bit 0; bit 7 -> Carry
    bcc loop
    rts

