.include "lib.h"
.include "sprites.h"

.rodata

SPRITE01=1; Player 1 neutral sprite
SPRITE02=2; Player 1 moving left
SPRITE03=3; Player 1 moving right
SPRITE04=4; Shot large star
SPRITE05=5; Shot charged beam
SPRITE06=6
SPRITE07=7
SPRITE08=8; Shot small star bullet
SPRITE09=9; Shot beam bullet
SPRITE0A=$0a;small explosion frame 0
SPRITE0B=$0b;small explosion frame 1
SPRITE0C=$0c;small explosion frame 2
SPRITE0D=$0d;small explosion frame 3
SPRITE0E=$0e; fairy frame 0
SPRITE0F=$0f; fairy frame 1 
SPRITE10=$10; balloon cannon frame 0 palette 2
SPRITE11=$11; balloon cannon frame 1 palette 2
SPRITE12=$12; available
SPRITE13=$13; available
SPRITE14=$14; available
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
SPRITE23=$23; mushroom idle
SPRITE24=$24; mushroom crouch
SPRITE25=$25; mushroom jump



; format
; 	Tile, Y, X, Attribute 
;
;attribute byte format
;76543210
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip nprite vertically
Sprite01:
	.lobytes 2, -14, -8, %0
	.lobytes 4, -14,  0, %0
	.lobytes 6,   2, -4, %0
	.byte NULL

Sprite02:
	.lobytes $14, -14, -8, %0
	.lobytes $16, -14,  0, %0
	.lobytes   6,   2, -4, %0
	.byte NULL

Sprite03:
	.lobytes $10, -14, -8, %0
	.lobytes $12, -14,  0, %0
	.lobytes   6,   2, -4, %0
	.byte NULL

Sprite04:

	.lobytes $20, -8, -8, %0
	.lobytes $20, -8,  0, %01000000
	.byte NULL
Sprite05:
	.lobytes $2E, -8, -8, %00000000
	.lobytes $2E, -8, 00, %01000000
	.byte NULL
Sprite06:
Sprite07:
Sprite08:
	.lobytes $22, -8, -4, %0
	.byte NULL
Sprite09:
	.lobytes $28, -8, -4, %0
	.byte NULL
Sprite0A:
	.byte 0, $40, %0, 0
	.byte 0, $40, %01000000, 8
	.byte TERMINATE
Sprite0B:
	.byte 0, $42, %0, 0
	.byte 0, $42, %01000000, 8
	.byte TERMINATE
Sprite0C:
	.byte 0, $44, %0, 0
	.byte 0, $44, %11000000, 8
	.byte TERMINATE
Sprite0D:
	.byte 0, $46, %0, 0
	.byte 0, $46, %11000000, 8
	.byte TERMINATE
Sprite0E:
	.lobytes $60, -8, -8, %00000001
	.lobytes $60, -8,  0, %01000001
	.byte NULL
Sprite0F:
	.lobytes $62, -8, -8, %00000001
	.lobytes $62, -8,  0, %01000001
	.byte NULL
Sprite10:
	.lobytes $64, -16, -8, %00000010
	.lobytes $64, -16,  0, %01000010
	.lobytes $66,   0, -8, %00000010
	.lobytes $66,   0,  0, %01000010
	.byte NULL
Sprite11:
	.lobytes $68, -16, -8, %00000010
	.lobytes $68, -16,  0, %01000010
	.lobytes $6a,   0, -8, %00000010
	.lobytes $6a,   0,  0, %01000010
	.byte NULL
Sprite12:
	.byte 0, $6c, %00000001, 0
	.byte 0, $6c, %01000001, 8
	.byte TERMINATE
Sprite13:
	.byte 0, $6e, %00000001, 0
	.byte 0, $6e, %01000001, 8
	.byte TERMINATE
Sprite14:
	.byte 0, $70, %00000001, 0
	.byte 0, $70, %01000001, 8
	.byte TERMINATE
Sprite15:
	.byte 0, $e0, %0, 0
	.byte 0, $e2, %0, 7
	.byte 0, $e4, %0, 14
	.byte 0, $e6, %0, 21
	.byte 0, $e8, %0, 28
	.byte 0, $ea, %0, 35 
	.byte TERMINATE
Sprite16:
	.byte 0, $ec, %0, 0
	.byte 0, $ee, %0, 7
	.byte 0, $f0, %0, 12
	.byte TERMINATE
Sprite17:
	.byte 0, $f6, %0, 0	
	.byte 0, $e4, %0, 07
	.byte 0, $f8, %0, 14
	.byte 0, $fa, %0, 21
	.byte 0, $e2, %0, 28
	.byte TERMINATE
Sprite18:
	.lobytes $a8, -16, -8, %01
	.lobytes $aa, -16,  0, %01
	.lobytes $ac,   0, -8, %10
	.lobytes $ae,   0,  0, %10
	.byte NULL
Sprite19:
	.lobytes $8,-4,-4,%0
	.byte NULL
	
Sprite1A:
	.lobytes $0A,-4,-4,%0
	.byte NULL
Sprite1B:
	.lobytes $0C,-4,-4,%0
	.byte NULL
Sprite1C:
	.lobytes $0A,-4,-4,%01000000
	.byte NULL
Sprite1D:
	.lobytes $0E,-4,-4,%0
	.byte NULL
Sprite1E:
	.byte 0,$3a,%0,0
	.byte TERMINATE
Sprite1F:
	.byte 0,$3c,%0,0
	.byte TERMINATE
Sprite20:
	.byte 0,$3e,%0,0
	.byte TERMINATE
Sprite21:
	.lobytes $a0, -16, -8, %01
	.lobytes $a2, -16,  0, %01
	.lobytes $a4,   0, -8, %10
	.lobytes $a6,   0,  0, %10
	.byte NULL
Sprite22:
	.byte 0,$3c,%01000000, 0
	.byte TERMINATE
Sprite23:
	.lobytes $72, -11, -8, %10
	.lobytes $74, -11,  0, %10
	.lobytes $76,  -6, -4, %10
	.byte NULL
Sprite24:
	.lobytes $72, -9, -8, %10
	.lobytes $74, -9,  0, %10
	.lobytes $76, -6, -4, %10000010
	.byte NULL
Sprite25:
	.lobytes $72, -18, -8, %10
	.lobytes $74, -18,  0, %10
	.lobytes $76,  -9, -4, %10
	.byte NULL
Sprite26:
Sprite27:
Sprite28:
Sprite29:
Sprite2A:
Sprite2B:
Sprite2C:
Sprite2D:
Sprite2E:
Sprite2F:

ANIMATION01=$01; Fairy
ANIMATION02=$02; Mushroom stand crouch
ANIMATION03=$03; Mushroom jump
ANIMATION04=$04; balloon cannon

Animation01:
	.byte SPRITE0E, 4, SPRITE0F, 4
	.byte NULL, 0


Animation02:
	.byte SPRITE23, 16, SPRITE24, 16


Animation03:
	.byte SPRITE25, 255


Animation04:
	.byte SPRITE10, 64, SPRITE11, 64
	.byte NULL, 0

;pointer table
Sprites_h:
	.byte NULL, >Sprite01, >Sprite02, >Sprite03, >Sprite04, >Sprite05, >Sprite06, >Sprite07, >Sprite08, >Sprite09, >Sprite0A, >Sprite0B, >Sprite0C, >Sprite0D, >Sprite0E, >Sprite0F
	.byte >Sprite10, >Sprite11, >Sprite12, >Sprite13, >Sprite14, >Sprite15, >Sprite16, >Sprite17, >Sprite18, >Sprite19, >Sprite1A, >Sprite1B, >Sprite1C, >Sprite1D, >Sprite1E, >Sprite1F
	.byte >Sprite20, >Sprite21, >Sprite22, >Sprite23, >Sprite24, >Sprite25, >Sprite26, >Sprite27, >Sprite28, >Sprite29, >Sprite2A, >Sprite2B, >Sprite2C, >Sprite2D, >Sprite2E, >Sprite2F
Sprites_l:
	.byte NULL, <Sprite01, <Sprite02, <Sprite03, <Sprite04, <Sprite05, <Sprite06, <Sprite07, <Sprite08, <Sprite09, <Sprite0A, <Sprite0B, <Sprite0C, <Sprite0D, <Sprite0E, <Sprite0F
	.byte <Sprite10, <Sprite11, <Sprite12, <Sprite13, <Sprite14, <Sprite15, <Sprite16, <Sprite17, <Sprite18, <Sprite19, <Sprite1A, <Sprite1B, <Sprite1C, <Sprite1D, <Sprite1E, <Sprite1F
	.byte <Sprite20, <Sprite21, <Sprite22, <Sprite23, <Sprite24, <Sprite25, <Sprite26, <Sprite27, <Sprite28, <Sprite29, <Sprite2A, <Sprite2B, <Sprite2C, <Sprite2D, <Sprite2E, <Sprite2F

Animations_l:
	.byte NULL,<Animation01,<Animation02,<Animation03,<Animation04
Animations_h:
	.byte NULL,>Animation01,>Animation02,>Animation03,>Animation04
