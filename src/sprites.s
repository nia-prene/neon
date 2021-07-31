.segment "SPRITES"

;76543210
;||||||||
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically
PLAYER_SPRITE = 0
TARGET_SPRITE = 1
PLAYER_MAIN_BULLET = 2
BULLET_SPRITE_0=3
BULLET_SPRITE_1=4
spriteTile0:
	.byte $00, $60, $20, $24, $26
spriteAttribute0:
	.byte %00000000, %00000010, %00000000, %00000011, %00000011
spriteTile1:
	.byte $02, $60, NULL, NULL, $26
spriteAttribute1:
	.byte %00000000, %01000010, NULL, NULL, %01000011
spriteTile2:
	.byte $04, $60, NULL, NULL, NULL
spriteAttribute2:
	.byte %00000000, %00000010, NULL, NULL, NULL
spriteTile3:
	.byte $06, $60, NULL, NULL, NULL
spriteAttribute3:
	.byte %00000000, %01000010, NULL, NULL, NULL

