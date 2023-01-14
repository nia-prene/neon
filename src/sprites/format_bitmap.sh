#!/bin/bash

#bitmaps start in the lower left, sprites start in the top right
< bitmaps/bitmap.bin xxd -p -c4 | tac | xxd -p -r > bitmaps/new.bin
