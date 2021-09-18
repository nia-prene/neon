.include "lib.h"
.include "sprites.h"

.rodata
PLAYER_SPRITE=0
LARGE_STAR=1
BULLET_SPRITE_0=2
BULLET_SPRITE_1=3
TARGET_SPRITE=4
HEART_SPRITE=5
HITBOX_SPRITE_1=6
HITBOX_SPRITE_2=7
SMALL_STAR=8
PLAYER_BEAM=9
;format
;name:
;	.byte Y offset, tile, attribute byte, X offset
;	.byte Y offset, tile, attribute byte, X offset
;	.byte etc
;	.byte NULL (terminate)
;attribute byte format
;76543210
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
sprite00:
	.byte 0, 0, %0, 0
	.byte 0, 2, %0, 8
	.byte 16, 4, %0, 0
	.byte NULL
sprite01:
	.byte 0, $20, %0, 0
	.byte 0, $20, %01000000, 8
	.byte NULL
sprite02:
	.byte 0, $24, %00000011, 0
	.byte NULL
sprite03:
	.byte 0, $26, %00000011, 0
	.byte 0, $26, %01000011, 8
	.byte NULL
sprite04:
	.byte 0, $60, %00000010, 0
	.byte 0, $60, %01000010, 8
	.byte NULL
sprite05:
	.byte 0, $0a, %0, 0
	.byte NULL
sprite06:
	.byte 16, $06, %0,0
	.byte NULL
sprite07:
	.byte 16, $08, %0,0
	.byte NULL
sprite08:
	.byte 0, $22, %0, 0
	.byte NULL
sprite09:
	.byte 0, $28, %0, 0
	.byte NULL
sprite10:
sprite11:
;pointers
spritesH:
	.byte >sprite00, >sprite01, >sprite02, >sprite03, >sprite04, >sprite05, >sprite06, >sprite07, >sprite08, >sprite09, >sprite10, >sprite11
spritesL:
	.byte <sprite00, <sprite01, <sprite02, <sprite03, <sprite04, <sprite05, <sprite06, <sprite07, <sprite08, <sprite09, <sprite10, <sprite11
