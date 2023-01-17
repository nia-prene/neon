#!/bin/bash

source colors.sh

declare colorargs=""

for i in "${!colors[@]}"
do
	declare arg=$(printf "xc:#%06X " $i)
	colorargs+="$arg"
done
#make the palette file
convert $colorargs +append pal.bmp
