.include "scenes.h"

.include "tiles.h"
.include "palettes.h"
.include "waves.h"
.include "bullets.h"
.include "speed.h"

.rodata
Scenes_tile:
	.byte BEACH_SCREEN
Scenes_palettes:
	.byte BEACH_PALETTE
Scenes_backgroundColor:
	.byte $0f
Scenes_waveString:
	.byte WAVESTRING00
Scenes_speed:
	.byte SPEED00
