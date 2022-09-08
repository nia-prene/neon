.include "lib.h"
.include "sprites.h"

.rodata

SPRITE01=1
SPRITE02=2
SPRITE03=3
LARGE_STAR=4;Large Star
HEART_SPRITE=5
SPRITE06=6; unused
SPRITE07=7; unused
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
SPRITE1E=$1e;small star charm spin front
SPRITE1F=$1f;small star charm spin left slant
SPRITE20=$20;small star charm spin side
SPRITE21=$21;piper frame 0
SPRITE22=$22;small star charm spin right slant

; format
; 	Tile, Y, X, Attribute 
;
;attribute byte format
;76543210
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
sprite01:
	.lobytes 2, -16, -8, %0
	.lobytes 4, -16,  0, %0
	.lobytes 6,   0, -6, %0
	.byte NULL

sprite02:
	.lobytes $24, -4, -4, %00000011
	.byte NULL
sprite03:
	.byte 0, $26, %00000011, 0
	.byte 0, $26, %01000011, 8
	.byte TERMINATE
sprite04:
	.byte 0, $20, %0, 0
	.byte 0, $20, %01000000, 8
	.byte TERMINATE
sprite05:
	.byte 0, $0a, %0, 0
	.byte TERMINATE
sprite06:
	.lobytes $08,-4,-4,%0
	.byte NULL
sprite07:
	.lobytes $0A,-4,-4,%0
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
	.lobytes $a8, -16, -8, %01
	.lobytes $aa, -16,  0, %01
	.lobytes $ac,   0, -8, %10
	.lobytes $ae,   0,  0, %10
	.byte NULL
sprite19:
	.lobytes $8,-4,-4,%0
	.byte NULL
	
sprite1A:
	.lobytes $0A,-4,-4,%0
	.byte NULL
sprite1B:
	.lobytes $0C,-4,-4,%0
	.byte NULL
sprite1C:
	.lobytes $0A,-4,-3,%01000000
	.byte NULL
sprite1D:
	.lobytes $0E,-4,-4,%0
	.byte NULL
sprite1E:
	.byte 0,$3a,%0,0
	.byte TERMINATE
sprite1F:
	.byte 0,$3c,%0,0
	.byte TERMINATE
sprite20:
	.byte 0,$3e,%0,0
	.byte TERMINATE
sprite21:
	.lobytes $a0, -16, -8, %01
	.lobytes $a2, -16,  0, %01
	.lobytes $a4,   0, -8, %10
	.lobytes $a6,   0,  0, %10
	.byte NULL
sprite22:
	.byte 0,$3c,%01000000, 0
	.byte TERMINATE
sprite23:
	.byte TERMINATE
sprite24:
	.byte TERMINATE
sprite25:
	.byte TERMINATE
sprite26:
	.byte TERMINATE
sprite27:
	.byte TERMINATE
sprite28:
	.byte TERMINATE
sprite29:
	.byte TERMINATE
sprite2A:
	.byte TERMINATE
sprite2B:
	.byte TERMINATE
sprite2C:
	.byte TERMINATE
sprite2D:
	.byte TERMINATE
sprite2E:
	.byte TERMINATE
sprite2F:
	.byte TERMINATE
	
;pointer table
spritesH:
	.byte NULL, >sprite01, >sprite02, >sprite03, >sprite04, >sprite05, >sprite06, >sprite07, >sprite08, >sprite09, >sprite0A, >sprite0B, >sprite0C, >sprite0D, >sprite0E, >sprite0F
	.byte >sprite10, >sprite11, >sprite12, >sprite13, >sprite14, >sprite15, >sprite16, >sprite17, >sprite18, >sprite19, >sprite1A, >sprite1B, >sprite1C, >sprite1D, >sprite1E, >sprite1F
	.byte >sprite20, >sprite21, >sprite22, >sprite23, >sprite24, >sprite25, >sprite26, >sprite27, >sprite28, >sprite29, >sprite2A, >sprite2B, >sprite2C, >sprite2D, >sprite2E, >sprite2F
spritesL:
	.byte NULL, <sprite01, <sprite02, <sprite03, <sprite04, <sprite05, <sprite06, <sprite07, <sprite08, <sprite09, <sprite0A, <sprite0B, <sprite0C, <sprite0D, <sprite0E, <sprite0F
	.byte <sprite10, <sprite11, <sprite12, <sprite13, <sprite14, <sprite15, <sprite16, <sprite17, <sprite18, <sprite19, <sprite1A, <sprite1B, <sprite1C, <sprite1D, <sprite1E, <sprite1F
	.byte <sprite20, <sprite21, <sprite22, <sprite23, <sprite24, <sprite25, <sprite26, <sprite27, <sprite28, <sprite29, <sprite2A, <sprite2B, <sprite2C, <sprite2D, <sprite2E, <sprite2F
