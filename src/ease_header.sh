#!/bin/bash
source ./src/ease.cfg

#ease in to a speed
for ease in ${!names[*]}
do
	printf '.global\tease_in%s_l\n' ${names[ease]}
	printf '.global\tease_in%s_h\n' ${names[ease]}
	printf '.global\tease_out%s_l\n' ${names[ease]}
	printf '.global\tease_out%s_h\n' ${names[ease]}
done
