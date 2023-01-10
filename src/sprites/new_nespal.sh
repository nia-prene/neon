#!/bin/sh
source colors.sh
declare colorargs=""

for i in "${colors[@]}"
do
	arg=$(printf 'xc:#%06X ' $i)
	colorargs+="$arg"
done
#make the palette file
convert $colorargs +append palette.gif
