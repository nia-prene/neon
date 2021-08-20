.segment "SPRITES"


PLAYER_SPRITE = 0
PLAYER_MAIN_BULLET = 1
BULLET_SPRITE_0=2
BULLET_SPRITE_1=3
TARGET_SPRITE = 4
spritesH:
	.byte >sprite00, >sprite01, >sprite02, >sprite03, >sprite04
spritesL:
	.byte <sprite00, <sprite01, <sprite02, <sprite03, <sprite04
;format
;name:
;	.byte Y offset, tile, Attribute, X Offset
;	.byte Y offset, tile, Attribute, X Offset
;	.byte etc
;	.byte NULL
;attribute format
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
