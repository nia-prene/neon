#!/usr/bin/perl
#converts 8x8 tile to chr
use strict;
use warnings;
use diagnostics;
use autodie;

open my $bmp, '<:raw', 'bitmaps/new.bin';
open my $chr, '>:raw', 'chr/test.chr';
my $plane1=0;
my $plane2=0;
my $rowswr=0;
while(read $bmp, my $bmprow, 4){
	$bmprow = unpack "N*", $bmprow;
	#printf "\n%032b\n",$bmprow;
	my $p1row=0;
	my $p2row=0;
	for(my $j=0; $j <8; $j++){
		my $bit1=($bmprow >> ((28)-($j*4)))&1;
		my $bit2=($bmprow >> (((28)-(($j*4)-1))))&1;
		#printf "%032b\n",$bit2;
		$p1row=($p1row | $bit1);
		$p2row=($p2row | $bit2);
		if($j<7){
			$p1row = $p1row << 1;
			$p2row = $p2row << 1;
		}
	}
	$plane1=($plane1 | $p1row);
	$plane2=($plane2 | $p2row);
	if($rowswr<7){
		$plane1=$plane1 << 8;
		$plane2=$plane2 << 8;
		$rowswr++;
	}else{
		print $chr pack('q>',$plane1);
		print $chr pack('q>',$plane2);
		$plane1=0;
		$plane2=0;
		$rowswr=0;	
	}
}
close $chr;
close $bmp;
