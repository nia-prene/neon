.include "lib.h"
.include "sprites.h"

.rodata
PLAYER_SPRITE=0
LARGE_STAR=1
BULLET_SPRITE_0=2
BULLET_SPRITE_1=3
TARGET_SPRITE=4
HEART_SPRITE=5
SPRITE06=6;player hitbox frame 0
SPRITE07=7;player hitbox frame 1
SMALL_STAR=8
PLAYER_BEAM=9
SPRITE0A=$0a;small explosion frame 0
SPRITE0B=$0b;small explosion frame 1
SPRITE0C=$0c;small explosion frame 2
SPRITE0D=$0d;small explosion frame 3
SPRITE0E=$0e;powerup frame 0
SPRITE0F=$0f;beach drone frame 0
SPRITE10=$10;balloon cannon frame 0
SPRITE11=$11;balloon cannon frame 1
SPRITE12=$12;submarine above water
SPRITE13=$13;submarine middle frame
SPRITE14=$14;submarine below water

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
	.byte 0, $06, %0,0
	.byte NULL
sprite07:
	.byte 0, $08, %0,0
	.byte NULL
sprite08:
	.byte 0, $22, %0, 0
	.byte NULL
sprite09:
	.byte 0, $28, %0, 0
	.byte NULL
sprite0A:
	.byte 0, $40, %0, 0
	.byte 0, $40, %01000000, 8
	.byte NULL
sprite0B:
	.byte 0, $42, %0, 0
	.byte 0, $42, %01000000, 8
	.byte NULL
sprite0C:
	.byte 0, $44, %0, 0
	.byte 0, $44, %11000000, 8
	.byte NULL
sprite0D:
	.byte 0, $46, %0, 0
	.byte 0, $46, %11000000, 8
	.byte NULL
sprite0E:
	.byte 0, $2a, %0, 0
	.byte 0, $2c, %0, 8
	.byte NULL
sprite0F:
	.byte 0, $62, %00000001, 0
	.byte 0, $62, %01000001, 8
	.byte NULL
sprite10:
	.byte 0, $64, %00000000, 0
	.byte 0, $64, %01000000, 8
	.byte 16, $66, %00000000, 0
	.byte 16, $66, %01000000, 8
	.byte NULL
sprite11:
	.byte 0, $68, %00000000, 0
	.byte 0, $68, %01000000, 8
	.byte 16, $6a, %00000000, 0
	.byte 16, $6a, %01000000, 8
	.byte NULL
sprite12:
	.byte 0, $6c, %00000001, 0
	.byte 0, $6c, %01000001, 8
	.byte NULL
sprite13:
	.byte 0, $6e, %00000001, 0
	.byte 0, $6e, %01000001, 8
	.byte NULL
sprite14:
	.byte 0, $70, %00000001, 0
	.byte 0, $70, %01000001, 8
	.byte NULL
;pointer table
spritesH:
	.byte >sprite00, >sprite01, >sprite02, >sprite03, >sprite04, >sprite05, >sprite06, >sprite07, >sprite08, >sprite09, >sprite0A, >sprite0B, >sprite0C, >sprite0D, >sprite0E, >sprite0F
	.byte >sprite10, >sprite11, >sprite12, >sprite13, >sprite14
spritesL:
	.byte <sprite00, <sprite01, <sprite02, <sprite03, <sprite04, <sprite05, <sprite06, <sprite07, <sprite08, <sprite09, <sprite0A, <sprite0B, <sprite0C, <sprite0D, <sprite0E, <sprite0F
	.byte <sprite10, <sprite11, <sprite12, <sprite13, <sprite14
