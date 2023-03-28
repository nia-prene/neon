COTTON_IDLE = $01
Animation01:
	.byte	COTTON_IDLE_00, COTTON_IDLE_01, COTTON_IDLE_02, COTTON_IDLE_03
	.byte	00

BREAKER_IDLE = $02
Animation02:
	.byte	BREAKER_IDLE_00, BREAKER_IDLE_01, BREAKER_IDLE_02, BREAKER_IDLE_03
	.byte	00



Animations_l:
	.byte	00
	.byte	<Animation01
	.byte	<Animation02
Animations_h:
	.byte	00
	.byte	>Animation01
	.byte	>Animation02
