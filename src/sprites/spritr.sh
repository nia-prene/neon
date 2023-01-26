#!/bin/bash
#include the color list
source colors.sh
declare bmp=$(convert +dither $1 -remap pal.bmp -compress none bmp:- \
	| xxd -p -u | tr -d '\n')
#get the bmp start from the header
declare  bmpstart=$(echo -n ${bmp:$((0x0A*2)):4} | tac -rs .. )
#get the bmp length from the header
declare bmplength=$(echo -n ${bmp:$((0x22*2)):4} | tac -rs ..)
#get the pixel width from the header
declare pxwidth=$(echo -n ${bmp:$((0x12*2)):4} | tac -rs ..)
pxwidth=$(bc<<<"obase=10;ibase=16;$pxwidth")
#get the pixel height from the header
declare pxheight=$(echo -n ${bmp:$((0x16*2)):4} | tac -rs ..)
#get the variable header length from the header
declare hdrlength=$(echo -n ${bmp:$((0x0E*2)):4} | tac -rs ..)
#colormap starts after the variable header and the fixed header (OE bytes)
declare colormap=$(bc <<< "ibase=16;$hdrlength + 0E")
#isolate the reference byte map, put a space between each 8 bit hex
declare bytemap=$(\
	echo -n ${bmp:$((0x$bmpstart*2)):$((0x$bmplength*2))} \
	| sed 's/.\{2\}/& /g'
)
# swap out the reference colors for the hex nes colors

declare nesmap=$(\
	declare writ=0
	for reference in $bytemap
	do
		# get the hex color by searching the colormap for the reference
		# chop off two leading 0s
		declare color=$(echo -n ${bmp:$((($colormap*2)+(8*0x$reference))):8} \
		| tac -rs .. \
		| sed 's/^..//')
		# search the nes colors for the hex color
		echo -n "$color "
		((writ++))
		newline=$(bc<<<"$writ%$pxwidth")
		if !((newline))
		then
			echo
		fi
	done
)
echo "$nesmap" | tac
