#!/usr/bin/perl
#converts 8bit bmp to 2bit nes
use strict;
use warnings;
use diagnostics;
use autodie;

use constant TLMODE => 16;

sub read_sprt {
	my ($sprtref)=@_;
	while (<>){
		push @{$sprtref}, [split];
	}
}

sub get_tlpal{
	my ($sprtref,$tl,$pxwdth,$pxhght) = @_;

	my %pal=();
	#get the top left pixel of the pixel data
	my $tl_x = ($tl % ($pxwdth / 8)) * 8;
	my $tl_y = (int(($tl) / ($pxwdth / 8))) * TLMODE;
	
	#for each pixel row in this tile	
	for (my $row=$tl_y; $row<($tl_y+16); $row++){
		#for each pixel in that row
		for (my $clmn=$tl_x; $clmn<($tl_x+8); $clmn++){
			#get the hex color
			my $clr=$sprtref->[$row][$clmn];
			#pop the color in the hash
			$pal{$clr}=(1);
		}
	}
	return (\%pal);
}

sub get_sprtdat {
	my ($sprtref)=@_;
	#get the sprite pixel dimensions
	my $pxwdth=scalar @{$sprtref->[0]};
	my $pxhght=scalar @{$sprtref};
	# convert it to tile dimensions
	my $tlwdth=$pxwdth/8;
	my $tlhght=$pxhght/16;
	my $tlcnt=$tlwdth*$tlhght;

	return ($pxwdth,$pxhght,$tlwdth,$tlhght,$tlcnt);
}

sub test_sprtdat{
	my ($sprtref, $pxwdth, $pxhght) = @_;
	if ($pxwdth % 8){
		die qq(nonstandard tile width, width must divide by 8);
	}
	if ($pxhght % TLMODE){
		die qq(nonstandard tile height, must divide by 8 for 8x8 mode, 16 for 8x16 mode);
	}
	for my $row (@{$sprtref}){
		if (@{$row} != $pxwdth){
			die qq(fatal error, tile row found of differing pixels);
		}
	}
}

sub test_tl{
	my ($sprtref,$pxwdth,$pxhght,$tl,$tlcnt)=@_;
	# count colors
	my $pal=get_tlpal($sprtref,$tl,$pxwdth,$pxhght);
	# if under 5
	if ((scalar %{$pal}) < 5){
		return 1;
	}
	return;
}

# reserve memory for sprite
my @sprt=();
# read data from stdin
read_sprt(\@sprt);
#extract usable data
my ($pxwdth,$pxhght,$tlhght,$tlwdth,$tlcnt) = get_sprtdat(\@sprt);
#test for usable data
test_sprtdat(\@sprt,$pxwdth,$pxhght);

for (my $tl=0;$tl<$tlcnt;$tl++){
	if (!test_tl(\@sprt,$pxwdth,$pxhght,$tl,$tlcnt)){
		print "tile bad\n"
	} else {
		print "tile good\n"
	}
}


