.include "speed.h"
.include "scenes.h"
.zeropage
Speed_pointer:
	.res 2
.data
Speed_string:
	.res 256

.code
Speed_setLevel:
;arguments
;x - current level
	lda Scenes_speed,x
	tax
	ldx #0
	lda Speed_string_L,x
	sta Speed_pointer
	lda Speed_string_H,x
	sta Speed_pointer+1

	ldy #0
@speedLoop:
	lda (Speed_pointer),y
	sta Speed_string,y
	iny
	bne @speedLoop
	rts

SPEED00=$00
Speed_string_L:
	.byte <speed00
Speed_string_H:
	.byte >speed00

speed00:
.byte 0, 2, 0, 0 
.byte 127, 2, 15, 0 
.byte 255, 1, 25, 0 
.byte 253, 2, 56, 0 
.byte 253, 1, 50, 0 
.byte 123, 2, 78, 0 
.byte 250, 1, 75, 0 
.byte 244, 2, 131, 0 
.byte 246, 1, 99, 0 
.byte 112, 2, 140, 0 
.byte 240, 1, 124, 0 
.byte 228, 2, 204, 0 
.byte 233, 1, 148, 0 
.byte 95, 2, 200, 0 
.byte 226, 1, 172, 0 
.byte 204, 2, 20, 1 
.byte 217, 1, 195, 0 
.byte 73, 2, 3, 1 
.byte 206, 1, 218, 0 
.byte 173, 2, 89, 1 
.byte 195, 1, 241, 0 
.byte 44, 2, 59, 1 
.byte 183, 1, 7, 1 
.byte 136, 2, 154, 1 
.byte 169, 1, 28, 1 
.byte 11, 2, 112, 1 
.byte 155, 1, 48, 1 
.byte 93, 2, 216, 1 
.byte 139, 1, 68, 1 
.byte 228, 1, 162, 1 
.byte 123, 1, 87, 1 
.byte 44, 2, 17, 2 
.byte 106, 1, 106, 1 
.byte 185, 1, 207, 1 
.byte 87, 1, 123, 1 
.byte 245, 1, 69, 2 
.byte 68, 1, 139, 1 
.byte 137, 1, 248, 1 
.byte 48, 1, 155, 1 
.byte 186, 1, 115, 2 
.byte 28, 1, 169, 1 
.byte 86, 1, 28, 2 
.byte 7, 1, 183, 1 
.byte 122, 1, 156, 2 
.byte 241, 0, 195, 1 
.byte 31, 1, 59, 2 
.byte 218, 0, 206, 1 
.byte 55, 1, 190, 2 
.byte 195, 0, 217, 1 
.byte 230, 0, 85, 2 
.byte 172, 0, 226, 1 
.byte 240, 0, 217, 2 
.byte 148, 0, 233, 1 
.byte 170, 0, 104, 2 
.byte 124, 0, 240, 1 
.byte 168, 0, 237, 2 
.byte 99, 0, 246, 1 
.byte 109, 0, 118, 2 
.byte 75, 0, 250, 1 
.byte 94, 0, 250, 2 
.byte 50, 0, 253, 1 
.byte 47, 0, 126, 2 
.byte 25, 0, 255, 1 
.byte 18, 0, 255, 2 
.byte 0, 0, 0, 2 
.byte 15, 0, 127, 2 
.byte 25, 0, 255, 1 
.byte 56, 0, 253, 2 
.byte 50, 0, 253, 1 
.byte 78, 0, 123, 2 
.byte 75, 0, 250, 1 
.byte 131, 0, 244, 2 
.byte 99, 0, 246, 1 
.byte 140, 0, 112, 2 
.byte 124, 0, 240, 1 
.byte 204, 0, 228, 2 
.byte 148, 0, 233, 1 
.byte 200, 0, 95, 2 
.byte 172, 0, 226, 1 
.byte 20, 1, 204, 2 
.byte 195, 0, 217, 1 
.byte 3, 1, 73, 2 
.byte 218, 0, 206, 1 
.byte 89, 1, 173, 2 
.byte 241, 0, 195, 1 
.byte 59, 1, 44, 2 
.byte 7, 1, 183, 1 
.byte 154, 1, 136, 2 
.byte 28, 1, 169, 1 
.byte 112, 1, 11, 2 
.byte 48, 1, 155, 1 
.byte 216, 1, 93, 2 
.byte 68, 1, 139, 1 
.byte 162, 1, 228, 1 
.byte 87, 1, 123, 1 
.byte 17, 2, 44, 2 
.byte 106, 1, 106, 1 
.byte 207, 1, 185, 1 
.byte 123, 1, 87, 1 
.byte 69, 2, 245, 1 
.byte 139, 1, 68, 1 
.byte 248, 1, 137, 1 
.byte 155, 1, 48, 1 
.byte 115, 2, 186, 1 
.byte 169, 1, 28, 1 
.byte 28, 2, 86, 1 
.byte 183, 1, 7, 1 
.byte 156, 2, 122, 1 
.byte 195, 1, 241, 0 
.byte 59, 2, 31, 1 
.byte 206, 1, 218, 0 
.byte 190, 2, 55, 1 
.byte 217, 1, 195, 0 
.byte 85, 2, 230, 0 
.byte 226, 1, 172, 0 
.byte 217, 2, 240, 0 
.byte 233, 1, 148, 0 
.byte 104, 2, 170, 0 
.byte 240, 1, 124, 0 
.byte 237, 2, 168, 0 
.byte 246, 1, 99, 0 
.byte 118, 2, 109, 0 
.byte 250, 1, 75, 0 
.byte 250, 2, 94, 0 
.byte 253, 1, 50, 0 
.byte 126, 2, 47, 0 
.byte 255, 1, 25, 0 
.byte 255, 2, 18, 0 
.byte 0, 2, 0, 0 
.byte 127, 2, 15, 0 
.byte 255, 1, 25, 0 
.byte 253, 2, 56, 0 
.byte 253, 1, 50, 0 
.byte 123, 2, 78, 0 
.byte 250, 1, 75, 0 
.byte 244, 2, 131, 0 
.byte 246, 1, 99, 0 
.byte 112, 2, 140, 0 
.byte 240, 1, 124, 0 
.byte 228, 2, 204, 0 
.byte 233, 1, 148, 0 
.byte 95, 2, 200, 0 
.byte 226, 1, 172, 0 
.byte 204, 2, 20, 1 
.byte 217, 1, 195, 0 
.byte 73, 2, 3, 1 
.byte 206, 1, 218, 0 
.byte 173, 2, 89, 1 
.byte 195, 1, 241, 0 
.byte 44, 2, 59, 1 
.byte 183, 1, 7, 1 
.byte 136, 2, 154, 1 
.byte 169, 1, 28, 1 
.byte 11, 2, 112, 1 
.byte 155, 1, 48, 1 
.byte 93, 2, 216, 1 
.byte 139, 1, 68, 1 
.byte 228, 1, 162, 1 
.byte 123, 1, 87, 1 
.byte 44, 2, 17, 2 
.byte 106, 1, 106, 1 
.byte 185, 1, 207, 1 
.byte 87, 1, 123, 1 
.byte 245, 1, 69, 2 
.byte 68, 1, 139, 1 
.byte 137, 1, 248, 1 
.byte 48, 1, 155, 1 
.byte 186, 1, 115, 2 
.byte 28, 1, 169, 1 
.byte 86, 1, 28, 2 
.byte 7, 1, 183, 1 
.byte 122, 1, 156, 2 
.byte 241, 0, 195, 1 
.byte 31, 1, 59, 2 
.byte 218, 0, 206, 1 
.byte 55, 1, 190, 2 
.byte 195, 0, 217, 1 
.byte 230, 0, 85, 2 
.byte 172, 0, 226, 1 
.byte 240, 0, 217, 2 
.byte 148, 0, 233, 1 
.byte 170, 0, 104, 2 
.byte 124, 0, 240, 1 
.byte 168, 0, 237, 2 
.byte 99, 0, 246, 1 
.byte 109, 0, 118, 2 
.byte 75, 0, 250, 1 
.byte 94, 0, 250, 2 
.byte 50, 0, 253, 1 
.byte 47, 0, 126, 2 
.byte 25, 0, 255, 1 
.byte 18, 0, 255, 2 
.byte 0, 0, 0, 2 
.byte 15, 0, 127, 2 
.byte 25, 0, 255, 1 
.byte 56, 0, 253, 2 
.byte 50, 0, 253, 1 
.byte 78, 0, 123, 2 
.byte 75, 0, 250, 1 
.byte 131, 0, 244, 2 
.byte 99, 0, 246, 1 
.byte 140, 0, 112, 2 
.byte 124, 0, 240, 1 
.byte 204, 0, 228, 2 
.byte 148, 0, 233, 1 
.byte 200, 0, 95, 2 
.byte 172, 0, 226, 1 
.byte 20, 1, 204, 2 
.byte 195, 0, 217, 1 
.byte 3, 1, 73, 2 
.byte 218, 0, 206, 1 
.byte 89, 1, 173, 2 
.byte 241, 0, 195, 1 
.byte 59, 1, 44, 2 
.byte 7, 1, 183, 1 
.byte 154, 1, 136, 2 
.byte 28, 1, 169, 1 
.byte 112, 1, 11, 2 
.byte 48, 1, 155, 1 
.byte 216, 1, 93, 2 
.byte 68, 1, 139, 1 
.byte 162, 1, 228, 1 
.byte 87, 1, 123, 1 
.byte 17, 2, 44, 2 
.byte 106, 1, 106, 1 
.byte 207, 1, 185, 1 
.byte 123, 1, 87, 1 
.byte 69, 2, 245, 1 
.byte 139, 1, 68, 1 
.byte 248, 1, 137, 1 
.byte 155, 1, 48, 1 
.byte 115, 2, 186, 1 
.byte 169, 1, 28, 1 
.byte 28, 2, 86, 1 
.byte 183, 1, 7, 1 
.byte 156, 2, 122, 1 
.byte 195, 1, 241, 0 
.byte 59, 2, 31, 1 
.byte 206, 1, 218, 0 
.byte 190, 2, 55, 1 
.byte 217, 1, 195, 0 
.byte 85, 2, 230, 0 
.byte 226, 1, 172, 0 
.byte 217, 2, 240, 0 
.byte 233, 1, 148, 0 
.byte 104, 2, 170, 0 
.byte 240, 1, 124, 0 
.byte 237, 2, 168, 0 
.byte 246, 1, 99, 0 
.byte 118, 2, 109, 0 
.byte 250, 1, 75, 0 
.byte 250, 2, 94, 0 
.byte 253, 1, 50, 0 
.byte 126, 2, 47, 0 
.byte 255, 1, 25, 0 
.byte 255, 2, 18, 0 

