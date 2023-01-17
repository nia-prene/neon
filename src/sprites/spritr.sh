#!/bin/bash
#include the color list
source colors.sh
#get the bmp start from the header
declare bmpstart=$(xxd -e -u -s 0x0A -l 4 $1 | awk '{print $2}')
#get the bmp length from the header
declare bmplength=$(xxd -e -u -s 0x22 -l 4 $1 | awk '{print $2}')
declare pxwidth=$(xxd -e -u -s 0x12 -l 4 $1 | awk '{print $2}')
declare pxheight=$(xxd -e -u -s 0x16 -l 4 $1 | awk '{print $2}')
declare hdrlength=$(xxd -e -u -s 0x0E -l 4 $1 | awk '{print $2}')
declare colormap=$(bc <<< "ibase=16;$hdrlength + 0E")
declare bmpmap=$(< $1 xxd -p -s 0x$bmpstart -l 0x$bmplength -c 0x$pxwidth \
	| tac \
	| xxd -r -p \
	| xxd -c1 -p)
declare nesmap=$(
for reference in $bmpmap
do
	declare hex=$(< $1 xxd -e -u -l4 -c4 \
		-s $(($colormap+(0x$reference*4))) \
		| awk '{print $2}' \
		| sed 's/^../0x/')
	printf "%02X" "0x${colors[$hex]}"
done
)
echo $nesmap | xxd -p -r | xxd -p -u -c32 

#color by reference
#declare reference=32
#< $1 xxd -e -u -s $(($colormap+(0x$reference*4))) -l4 -c4| awk '{print $2}'

