#!/bin/bash

source colors.sh
echo "#!/usr/bin/perl"
echo
echo "my %colors = ("
for color in "${!colors[@]}"
do
	printf "\t\"%06X\" => \"${colors[$color]}\",\n" $color
done
printf ");"
