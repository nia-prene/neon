#!/bin/bash
source spritr.cfg

#limit to 16 colors, remap to the NES palette, and stamp out sprites
convert +dither sprite02.png -colors 16 -remap nespal.gif -crop 8x${HEIGHT} -colors 4 tiles/tile.bmp
