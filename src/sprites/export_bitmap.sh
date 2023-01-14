#!/bin/bash

declare start=$(xxd -p -g 4 -s 0x0A -l 1 tiles/tile-0.bmp)
declare length=$(xxd -p -g 4 -s 0x22 -l 1 tiles/tile-0.bmp)
echo $start
echo $length

dd if=tiles/tile-0.bmp of=bitmaps/bitmap.bin skip=$(("0x$start")) count=$(("0x$length")) bs=1
