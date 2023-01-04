#!/bin/bash
source bashnes.sh

bytes=16
halves="Ease_inHalves"
fastest=7.5
printf '.include "enemies.h"\n'
printf '\n'
printf '.rodata\n'
printf '\n'

printf '%s_l:\n' $halves
for (( i=0; i<bytes; i++ ))
do
	step=$(bc <<<"scale=2; $i / ($bytes-1)")
	ease=$(ease_in $step)
	speed=$(bc <<< "scale=2; $fastest * $ease")
	print_hex $i $bytes $(get_lo $speed)

done
printf '\n'
printf '%s_h:\n' $halves
for (( i=0; i<bytes; i++ ))
do
	step=$(bc <<<"scale=2; $i / ($bytes-1)")
	ease=$(ease_in $step)
	speed=$(bc <<< "scale=2; $fastest * $ease")
	print_hex $i $bytes $(get_hi $speed)
done
