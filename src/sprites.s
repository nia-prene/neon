.include "lib.h"
.include "sprites.h"

.rodata

SPRITE01	=$01;	Player 1 neutral sprite
SPRITE02	=$02; 	Player 1 moving left
SPRITE03	=$03; 	Player 1 moving right
SPRITE04	=$04;	Shot large star
SPRITE05	=$05; 	Shot charged beam
SPRITE06	=$06;	crumpled beam 1
SPRITE07	=$07;	crumpled beam 2
SPRITE08	=$08; 	Shot small star
SPRITE09	=$09; 	Shot beam 
SPRITE0A	=$0a;	small explosion frame 0
SPRITE0B	=$0b;	small explosion frame 1
SPRITE0C	=$0c;	small explosion frame 2
SPRITE0D	=$0d;	small explosion frame 3
SPRITE0E	=$0e;	fairy frame 0
SPRITE0F	=$0f; 	fairy frame 1 
SPRITE10	=$10; 	balloon cannon frame 0 palette 2
SPRITE11	=$11; 	balloon cannon frame 1 palette 2
SPRITE12	=$12;	Shot large star crumple
SPRITE13	=$13;	empty broom 
SPRITE14	=$14;	falling off broom
SPRITE15	=$15;	Ready?
SPRITE16	=$16;	Go!
SPRITE17	=$17;	PAUSE
SPRITE18	=$18;	reese hands up
SPRITE19	=$19;	hitbox main frame 1
SPRITE1A	=$1a;	hitbox main frame 2
SPRITE1B	=$1b;	hitbox main frame 3
SPRITE1C	=$1c;	hitbox main frame 4
SPRITE1D	=$1d;	hitbox deploying
SPRITE1E	=$1e;	small star charm spin front
SPRITE1F	=$1f;	small star charm spin left slant
SPRITE20	=$20;	small star charm spin side
SPRITE21	=$21;	reese idle
SPRITE22	=$22;	small star charm spin right slant
SPRITE23	=$23;	mushroom idle
SPRITE24	=$24;	mushroom crouch
SPRITE25	= $25;	mushroom jump
SPRITE26	= $26;	powerup small
SPRITE27	= $27;	powerup large
SPRITE28	= $28;	bullet 11
SPRITE29	= $29;	bullet 01
SPRITE2A	= $2A;	bullet 10
SPRITE2B	= $2B;	game over
SPRITE2C	= $2C;	card quarter turned front
SPRITE2D	= $2D;	card sideways
SPRITE2E	= $2E;	card turned back
SPRITE2F	= $2F;	card quarter turned back returning
SPRITE30	= $30;	
SPRITE31	= $31;	card quarter turned front returning
SPRITE32	= $32;	sideways right


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
	.lobytes 	$2E,	-8, 	-8, 	%00000000
	.lobytes 	$2E, 	-8, 	00, 	%01000000
	.byte 		NULL
Sprite06:
	.lobytes	$32,	-8,	-4,	%00
	.byte		NULL
Sprite07:
	.lobytes	$34,	-08,	-4,	%00
	.byte		NULL
Sprite08:
	.lobytes $22, -8, -4, %0
	.byte NULL
Sprite09:
	.lobytes $28, -8, -4, %0
	.byte NULL
Sprite0A:;		explosion frame 1
	.lobytes	$40,	-8,	-8,	%0
	.lobytes	$40,	-8,	 0,	%11000000
	.byte		NULL
Sprite0B:;		explosion frame 2
	.lobytes	$42,	-8,	-8,	%0
	.lobytes	$42,	-8,	 0,	%11000000
	.byte		NULL
Sprite0C:;		explosion frame 3
	.lobytes	$44,	-8,	-8,	%0
	.lobytes	$44,	-8,	 0,	%11000000
	.byte		NULL
Sprite0D:;		explosion frame 4
	.lobytes	$46,	-8,	-8,	%0
	.lobytes	$46,	-8,	 0,	%11000000
	.byte		NULL
Sprite0E:
	.lobytes $60, -8, -8, %00000010
	.lobytes $60, -8,  0, %01000010
	.byte NULL
Sprite0F:
	.lobytes $62, -8, -8, %00000010
	.lobytes $62, -8,  0, %01000010
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
	.lobytes $22, -8, -8, %0
	.lobytes $22, -8,  0, %01000000
	.byte NULL

Sprite13:
	.lobytes	$1A,	-16,	-4,	%00
	.lobytes	$18,	0,	-4,	%00
	.byte		NULL
Sprite14:
	.lobytes	$1C,	-8,	0,	%00
	.lobytes	$1E,	-8,	8,	%00
	.byte		NULL
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
	.lobytes 	$3a,	-04,	-04,	%0
	.byte NULL
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
	.lobytes $72, -11, -8, %01
	.lobytes $74, -11,  0, %01
	.lobytes $76,  -6, -4, %01
	.byte NULL
Sprite24:
	.lobytes $72, -9, -8, %01
	.lobytes $74, -9,  0, %01
	.lobytes $76, -6, -4, %10000001
	.byte NULL
Sprite25:
	.lobytes $72, -18, -8, %01
	.lobytes $74, -18,  0, %01
	.lobytes $76,  -9, -4, %01
	.byte NULL
Sprite26:
	.lobytes $2E,	 -08,	-04,	%00
	.byte NULL
Sprite27:
	.lobytes $2A,	 -08,	-16,	%00
	.lobytes $2C,	 -08,	 00,	%00
	.byte NULL
Sprite28:
	.lobytes $24,	 -04,	-04,	%11
	.byte NULL
Sprite29:
	.lobytes $24,	 -04,	-04,	%01
	.byte NULL
Sprite2A:
	.lobytes $24,	 -04,	-04,	%10
	.byte NULL
Sprite2B:
	.lobytes $EC, -8, -(((4*7)+4)+1), %0
	.lobytes $E4, -8, -(((3*7)+4)+1), %0
	.lobytes $F2, -8, -(((2*7)+4)+1), %0
	.lobytes $E2, -8, -((1*7)+4), %0
	
	.lobytes $EE, -8, (0*7)+4, %0
	.lobytes $F4, -8, (1*7)+4, %0
	.lobytes $E2, -8, (2*7)+4, %0
	.lobytes $E0, -8, (3*7)+4, %0
	.byte NULL

Sprite2C:
	.lobytes $30, -8, -4, %0
	.byte NULL
Sprite2D:
	.lobytes $36, -8, -4, %0
	.byte NULL
Sprite2E:
	.lobytes $2A, -8, -4, %0
	.byte NULL
Sprite2F:
	.lobytes $2C, -8, -4, %0
	.byte NULL
Sprite30:
	.lobytes $2A, -8, -4, %01000000
	.byte NULL
Sprite31:
	.lobytes $4E, -8, -4, %00
	.byte NULL
Sprite32:
	.lobytes $36, -8, -4, %01000000
	.byte NULL

ANIMATION01	= $01; 	Fairy
ANIMATION02	= $02; 	Mushroom stand crouch
ANIMATION03	= $03; 	Mushroom jump
ANIMATION04	= $04; 	balloon cannon
ANIMATION05	= $05; 	Mushroom standing
ANIMATION06	= $06;	explosion
ANIMATION07	= $07;	shot crumpling
ANIMATION08	= $08;	missile crumpling
ANIMATION09	= $09;	reese idle
ANIMATION0A	= $0A;	reese hands up
ANIMATION0B	= $0B;	spinning card

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


Animation05:
	.byte SPRITE23, 255
	.byte NULL, 0


Animation06:
	.byte SPRITE0A, 6, SPRITE0B, 6, SPRITE0C, 6, SPRITE0D, 6
	.byte NULL

Animation07:
	.byte SPRITE06, 1, SPRITE07, 1
	.byte NULL


Animation08:
	.byte SPRITE12, 2
	.byte NULL

Animation09:
	.byte SPRITE21, 255
	.byte NULL, 0
Animation0A:
	.byte SPRITE18, 255
	.byte NULL, 0
Animation0B:
	.byte SPRITE26, 6
	.byte SPRITE2C, 6
	.byte SPRITE2D, 6
	.byte SPRITE2E, 6
	.byte SPRITE2F, 6
	.byte SPRITE30, 6
	.byte SPRITE32, 6
	.byte SPRITE31, 6
	.byte NULL, 0
Sprites_h:
	.byte NULL, >Sprite01, >Sprite02, >Sprite03, >Sprite04, >Sprite05, >Sprite06, >Sprite07, >Sprite08, >Sprite09, >Sprite0A, >Sprite0B, >Sprite0C, >Sprite0D, >Sprite0E, >Sprite0F
	.byte >Sprite10, >Sprite11, >Sprite12, >Sprite13, >Sprite14, >Sprite15, >Sprite16, >Sprite17, >Sprite18, >Sprite19, >Sprite1A, >Sprite1B, >Sprite1C, >Sprite1D, >Sprite1E, >Sprite1F
	.byte >Sprite20, >Sprite21, >Sprite22, >Sprite23, >Sprite24, >Sprite25, >Sprite26, >Sprite27, >Sprite28, >Sprite29, >Sprite2A, >Sprite2B, >Sprite2C, >Sprite2D, >Sprite2E, >Sprite2F
	.byte >Sprite30, >Sprite31, >Sprite32
Sprites_l:
	.byte NULL, <Sprite01, <Sprite02, <Sprite03, <Sprite04, <Sprite05, <Sprite06, <Sprite07, <Sprite08, <Sprite09, <Sprite0A, <Sprite0B, <Sprite0C, <Sprite0D, <Sprite0E, <Sprite0F
	.byte <Sprite10, <Sprite11, <Sprite12, <Sprite13, <Sprite14, <Sprite15, <Sprite16, <Sprite17, <Sprite18, <Sprite19, <Sprite1A, <Sprite1B, <Sprite1C, <Sprite1D, <Sprite1E, <Sprite1F
	.byte <Sprite20, <Sprite21, <Sprite22, <Sprite23, <Sprite24, <Sprite25, <Sprite26, <Sprite27, <Sprite28, <Sprite29, <Sprite2A, <Sprite2B, <Sprite2C, <Sprite2D, <Sprite2E, <Sprite2F
	.byte <Sprite30, <Sprite31, <Sprite32

Animations_l:
	.byte NULL,<Animation01,<Animation02,<Animation03
	.byte <Animation04,<Animation05,<Animation06,<Animation07
	.byte <Animation08,<Animation09,<Animation0A,<Animation0B
Animations_h:
	.byte NULL,>Animation01,>Animation02,>Animation03
	.byte >Animation04,>Animation05,>Animation06,>Animation07
	.byte >Animation08,>Animation09,>Animation0A,>Animation0B
