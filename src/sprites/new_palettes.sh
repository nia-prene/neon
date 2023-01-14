#!/bin/bash
source spritr.cfg

convert +dither sprite02.png -colors 16 -remap nespal.gif -crop 8x${HEIGHT} -unique-colors -colors 4 palettes/pal.bmp
