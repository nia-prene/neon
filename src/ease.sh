#!/bin/bash
source bashnes.sh
source ./src/ease.cfg

#file header info
printf '.include "ease.h"\n'
printf '\n'
printf '.rodata\n'
printf '\n'

#each ease is 16 bytes
declare -ir bytes=16

#ease in to a speed
for ease in ${!values[*]}
do
	printf 'ease_in%s_l:\n' ${names[ease]}

	for (( i=0; i<bytes; i++ ))
	do
		speed=$(ease_in 0 ${values[ease]} $i $bytes)
		print_byte $i $bytes $(get_lo $speed)
	done
	
	printf '\n'
	printf 'ease_in%s_h:\n' ${names[ease]}
	
	for (( i=0; i<bytes; i++ ))
	do
		speed=$(ease_in 0 ${values[ease]} $i $bytes)
		print_byte $i $bytes $(get_hi $speed)
	done
	printf '\n'
done

#ease out of a speed
for ease in ${!values[*]}
do
	printf 'ease_out%s_l:\n' ${names[ease]}

	for (( i=0; i<bytes; i++ ))
	do
		speed=$(ease_out ${values[ease]} 0 $i $bytes)
		print_byte $i $bytes $(get_lo $speed)
	done
	
	printf '\n'
	printf 'ease_out%s_h:\n' ${names[ease]}
	
	for (( i=0; i<bytes; i++ ))
	do
		speed=$(ease_out ${values[ease]} 0 $i $bytes)
		print_byte $i $bytes $(get_hi $speed)
	done
	printf '\n'
done
