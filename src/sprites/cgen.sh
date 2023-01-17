#!/bin/bash

source backupcolors.sh

printf "declare -A colors=(\n"

for ((i=0;i<${#colors[@]};i++))
do
	if [[ "${colors[$i]}" -eq "0" ]]
	then
		printf "\t[0x%06X]="\""0F"\""\n" ${colors[$i]}
	else
		printf "\t[0x%06X]="\""%02X"\""\n" ${colors[$i]} $i
	fi
done
printf "\t)"
