#!/bin/bash

written=0
for folder in sprites/*
do 
	for file in $folder/*.gif
	do
		# the name of the animation is the .gif file name
		name=$(basename -s .gif $file)

		# break it into numbered frames with imagemagick
		convert $file -coalesce $folder/$name\_%02d.png

		# get all the frame names
		frames=$(basename -s .png $folder/$name\_*)
		
		# start printing assembly file
		printf "%s = $%02X\n" ${name^^} $((++written))
		printf "Animation%02X:\n" $written
		printf "\t.byte\t"

		# print the frame names with comma separation 
		echo ${frames^^} | sed 's/ /, /g'

		#null terminate
		printf "\t.byte\t00\n\n"
	done
done

printf "\n\n"
printf "Animations_l:\n\t.byte\t00\n"
for i in $( seq 1 $written)
do
	printf "\t.byte\t<Animation%02X\n" $i
done

printf "Animations_h:\n\t.byte\t00\n"
for i in $( seq 1 $written)
do
	printf "\t.byte\t>Animation%02X\n" $i
done
