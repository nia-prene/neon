#!/usr/bin/perl
#converts 4bpp bmp to 2bpp nes
use strict;
use warnings;
use diagnostics;
use autodie;

my $plane1=0;
my $plane2=0;
my $completed=0;

binmode(STDIN);
binmode(STDOUT);

while(read STDIN, my $buffer, 4){
	my $bmprow = unpack "N*", $buffer;
	my $p1row=0;
	my $p2row=0;
	for(my $pixel=0; $pixel <8; $pixel++){
		my $bit1=($bmprow >> ((28)-($pixel*4)))&1;
		my $bit2=($bmprow >> (((28)-(($pixel*4)-1))))&1;
		$p1row=($p1row | $bit1);
		$p2row=($p2row | $bit2);
		if($pixel<7){
			$p1row = $p1row << 1;
			$p2row = $p2row << 1;
		}
	}
	$plane1=($plane1 | $p1row);
	$plane2=($plane2 | $p2row);
	if($completed++<7){
		$plane1=$plane1 << 8;
		$plane2=$plane2 << 8;
	}else{
		print pack('q>',$plane1);
		print pack('q>',$plane2);
		$plane1=0;
		$plane2=0;
		$completed=0;	
	}
}
