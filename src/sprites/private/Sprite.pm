#!/usr/bin/perl
package Sprite;
use strict;
use warnings;

use constant TILE_MODE => 16;
sub new{
	my $class = shift;
	my $pixels = shift;

	my $pixel_width = scalar @{$pixels->[0]};
	my $pixel_height = scalar @{$pixels};
	my $tile_width = $pixel_width / 8;
	my $tile_height = $pixel_height / TILE_MODE;
	my $tile_count = $tile_width * $tile_height;
	
	my $self = {
		pixels => $pixels,
		pixel_width => $pixel_width,
		pixel_height => $pixel_height,
		tile_width => $tile_width,
		tile_height => $tile_height,
		tile_count => $tile_count
	};
	bless $self, $class;
	return $self;
};


sub pixels{
	my $self = shift;
	return $self->{pixels};
}


sub pixel_width{
	my $self = shift;
	return $self->{pixel_width};
}


sub pixel_height{
	my $self = shift;
	return $self->{pixel_height};
}


sub tile_width{
	my $self = shift;
	return $self->{tile_width};
}


sub tile_height{
	my $self = shift;
	return $self->{tile_height};
}


sub tile_count{
	my $self = shift;
	return $self->{tile_count};
}


sub tile_palette{
	my $self = shift;
	my $tile = shift;
	my %palette=();
	
	#get the top left pixel of the pixel data
	my $tile_x = ($tile % ($self->{pixel_width} / 8)) * 8;
	my $tile_y = (int(($tile) / ($self->{pixel_width} / 8)))* TILE_MODE;
	#for each pixel row in this tile	
	for (my $row = $tile_y; $row < ($tile_y + TILE_MODE); $row++){
		#for each pixel in that row
		for (my $column = $tile_x; $column < ($tile_x + 8); $column++){
			#get the hex color
			my $color = $self->{pixels}[$row][$column];
			#pop the color in the hash
			$palette{$color}=(1);
		}
	}
	return (\%palette);
}


sub test_tile{
	my $self = shift;
	my $tile = shift;
	# count colors
	my $palette = $self->tile_palette($tile);
	# if under 5
	if ((scalar %{$palette}) < 5){
		return 1;
	}
	return;
}


1;

=pod

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

sub test_row{
	my ($sprite, $pxwdth, $pxhght, $tlwdth, $tlhght, $tlcnt) = @_;
	for (my $tile=$row*$tlwdth; $tile<($row*$tlwdth)+$tlwdth; $tile++){
		if (!test_tl($sprt,$pxwdth,$pxhght,$tl,$tlcnt)){
			return;
		}
	}
	return 1;
}


sub resolve_sprt{

	my ($sprt,$pxwdth,$pxhght,$tlwdth,$tlhght,$tlcnt)=@_;
	my @bdclmns=();
	my @bdrws=();
	for (my $tile_row=0;$tile_row<$tlhght;$tile_row++){
	}

	for (my $clmn=0;$clmn<$tlwdth;$clmn++){
		for (my $tl=$clmn;$tl<$tlcnt;$tl+=$tlwdth){
			if (!test_tl($sprt,$pxwdth,$pxhght,$tl,$tlcnt)){
				push @bdclmns, $clmn;
			}
		}
	}
}
sub test_right_edge{
	
}
=cut


