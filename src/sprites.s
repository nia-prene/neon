.include "lib.h"
.include "sprites.h"

.rodata
PLAYER_SPRITE=0
LARGE_STAR=1
SPRITE02=2
SPRITE03=3
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
SPRITE15=$15;Ready?
SPRITE16=$16;Go!
SPRITE17=$17;PAUSE
SPRITE18=$18;Piper attack animation
SPRITE19=$19;hitbox main frame 1
SPRITE1A=$1a;hitbox main frame 2
SPRITE1B=$1b;hitbox main frame 3
SPRITE1C=$1c;hitbox main frame 4
SPRITE1D=$1d;hitbox deploying
SPRITE1E=$1e;small coin flat 
SPRITE1F=$1f;
SPRITE20=$20;
SPRITE21=$21;piper frame 0

;format
;name:
;	.byte Y offset, tile, attribute byte, X offset
;	.byte Y offset, tile, attribute byte, X offset
;	.byte etc
;	.byte TERMINATE (terminate)
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
	.byte 16, 4, %0, 2
	.byte TERMINATE
sprite01:
	.byte 0, $20, %0, 0
	.byte 0, $20, %01000000, 8
	.byte TERMINATE
sprite02:
	.byte 0, $24, %00000011, 0
	.byte TERMINATE
sprite03:
	.byte 0, $26, %00000011, 0
	.byte 0, $26, %01000011, 8
	.byte TERMINATE
sprite04:
	.byte 0, $60, %00000010, 0
	.byte 0, $60, %01000010, 8
	.byte TERMINATE
sprite05:
	.byte 0, $0a, %0, 0
	.byte TERMINATE
sprite06:
	.byte 0, $06, %0,0
	.byte TERMINATE
sprite07:
	.byte 0, $08, %0,0
	.byte TERMINATE
sprite08:
	.byte 0, $22, %0, 0
	.byte TERMINATE
sprite09:
	.byte 0, $28, %0, 0
	.byte TERMINATE
sprite0A:
	.byte 0, $40, %0, 0
	.byte 0, $40, %01000000, 8
	.byte TERMINATE
sprite0B:
	.byte 0, $42, %0, 0
	.byte 0, $42, %01000000, 8
	.byte TERMINATE
sprite0C:
	.byte 0, $44, %0, 0
	.byte 0, $44, %11000000, 8
	.byte TERMINATE
sprite0D:
	.byte 0, $46, %0, 0
	.byte 0, $46, %11000000, 8
	.byte TERMINATE
sprite0E:
	.byte 0, $2a, %0, 0
	.byte 0, $2c, %0, 8
	.byte TERMINATE
sprite0F:
	.byte 0, $62, %00000001, 0
	.byte 0, $62, %01000001, 8
	.byte TERMINATE
sprite10:
	.byte 0, $64, %00000000, 0
	.byte 0, $64, %01000000, 8
	.byte 16, $66, %00000000, 0
	.byte 16, $66, %01000000, 8
	.byte TERMINATE
sprite11:
	.byte 0, $68, %00000000, 0
	.byte 0, $68, %01000000, 8
	.byte 16, $6a, %00000000, 0
	.byte 16, $6a, %01000000, 8
	.byte TERMINATE
sprite12:
	.byte 0, $6c, %00000001, 0
	.byte 0, $6c, %01000001, 8
	.byte TERMINATE
sprite13:
	.byte 0, $6e, %00000001, 0
	.byte 0, $6e, %01000001, 8
	.byte TERMINATE
sprite14:
	.byte 0, $70, %00000001, 0
	.byte 0, $70, %01000001, 8
	.byte TERMINATE
sprite15:
	.byte 0, $e0, %0, 0
	.byte 0, $e2, %0, 7
	.byte 0, $e4, %0, 14
	.byte 0, $e6, %0, 21
	.byte 0, $e8, %0, 28
	.byte 0, $ea, %0, 35 
	.byte TERMINATE
sprite16:
	.byte 0, $ec, %0, 0
	.byte 0, $ee, %0, 7
	.byte 0, $f0, %0, 12
	.byte TERMINATE
sprite17:
	.byte 0, $f6, %0, 0	
	.byte 0, $e4, %0, 07
	.byte 0, $f8, %0, 14
	.byte 0, $fa, %0, 21
	.byte 0, $e2, %0, 28
	.byte TERMINATE
sprite18:
	.byte 0, $a8, %01, 0
	.byte 0, $aa, %01, 8
	.byte 16, $ac, %10, 0
	.byte 16, $ae, %10, 8
	.byte TERMINATE
sprite19:
	.byte 0,$06,%0,0
	.byte TERMINATE
sprite1A:
	.byte 0,$08,%0,0
	.byte TERMINATE
sprite1B:
	.byte 0,$0A,%0,0
	.byte TERMINATE
sprite1C:
	.byte 0,$08,%01000000,1
	.byte TERMINATE
sprite1D:
	.byte 0,$0c,%0,0
	.byte TERMINATE
sprite1E:
	.byte 0,$38,%0,0
	.byte TERMINATE
sprite1F:
	.byte TERMINATE
sprite20:
	.byte TERMINATE
sprite21:
	.byte 0, $a0, %01, 0
	.byte 0, $a2, %01, 8
	.byte 16, $a4, %10, 0
	.byte 16, $a6, %10, 8
	.byte TERMINATE
sprite22:
	
;pointer table
spritesH:
	.byte >sprite00, >sprite01, >sprite02, >sprite03, >sprite04, >sprite05, >sprite06, >sprite07, >sprite08, >sprite09, >sprite0A, >sprite0B, >sprite0C, >sprite0D, >sprite0E, >sprite0F
	.byte >sprite10, >sprite11, >sprite12, >sprite13, >sprite14, >sprite15, >sprite16, >sprite17, >sprite18, >sprite19, >sprite1A, >sprite1B, >sprite1C, >sprite1D, >sprite1E, >sprite1F
	.byte >sprite20, >sprite21
spritesL:
	.byte <sprite00, <sprite01, <sprite02, <sprite03, <sprite04, <sprite05, <sprite06, <sprite07, <sprite08, <sprite09, <sprite0A, <sprite0B, <sprite0C, <sprite0D, <sprite0E, <sprite0F
	.byte <sprite10, <sprite11, <sprite12, <sprite13, <sprite14, <sprite15, <sprite16, <sprite17, <sprite18, <sprite19, <sprite1A, <sprite1B, <sprite1C, <sprite1D, <sprite1E, <sprite1F
	.byte <sprite20, <sprite21
