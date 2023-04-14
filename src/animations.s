BULLET_LARGE = $01
Animation01:
	.byte	BULLET_LARGE_00, BULLET_LARGE_01, BULLET_LARGE_02, BULLET_LARGE_03, BULLET_LARGE_04, BULLET_LARGE_05, BULLET_LARGE_06, BULLET_LARGE_07
	.byte	00

BULLET_SMALL = $02
Animation02:
	.byte	BULLET_SMALL_00, BULLET_SMALL_01, BULLET_SMALL_02, BULLET_SMALL_03, BULLET_SMALL_04, BULLET_SMALL_05, BULLET_SMALL_06, BULLET_SMALL_07
	.byte	00

PLAYER_IDLE = $03
Animation03:
	.byte	PLAYER_IDLE_00
	.byte	00

COTTON_IDLE = $04
Animation04:
	.byte	COTTON_IDLE_00, COTTON_IDLE_01, COTTON_IDLE_02, COTTON_IDLE_03
	.byte	00

BREAKER_IDLE = $05
Animation05:
	.byte	BREAKER_IDLE_00, BREAKER_IDLE_01, BREAKER_IDLE_02, BREAKER_IDLE_03
	.byte	00



Animations_l:
	.byte	00
	.byte	<Animation01
	.byte	<Animation02
	.byte	<Animation03
	.byte	<Animation04
	.byte	<Animation05
Animations_h:
	.byte	00
	.byte	>Animation01
	.byte	>Animation02
	.byte	>Animation03
	.byte	>Animation04
	.byte	>Animation05
