.include "scenes.h"
.include "lib.h"

.include "bullets.h"
.include "tiles.h"
.include "palettes.h"
.include "waves.h"

SCENE00		= 0
SCENE01		= 1
.rodata
Scenes_screen:
	.byte SCREEN00,SCREEN01
Scenes_palettes:
	.byte BEACH_PALETTE,COLLECTION01
Scenes_backgroundColor:
	.byte $2c,$22
Scenes_waveString:
	.byte WAVESTRING00,NULL
