.include "scenes.h"

.include "tiles.h"
.include "palettes.h"
.include "waves.h"
.include "bullets.h"

.rodata
Scenes_screen:
	.byte SCREEN00
Scenes_palettes:
	.byte BEACH_PALETTE
Scenes_backgroundColor:
	.byte $2c
Scenes_waveString:
	.byte WAVESTRING00
