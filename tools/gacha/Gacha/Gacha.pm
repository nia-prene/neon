#!/isr/bin/env perl

use strict;
use warnings;
use autodie;

package Gacha;
use Gacha::Ball;
use Gacha::Sprite;
use Gacha::Tile;


sub new {
	my $class = shift;
	return bless {}, $class;
}


sub balls {
	my $self = shift;
	if (@_) {
		$self->{balls} = shift;
	}
	return $self->{balls};
}


sub palettes {
	my $self = shift;
	if (@_) {
		$self->{palettes} = shift;
	}
	return $self->{palettes};
}


sub tiles {
	my $self = shift;
	if (@_) {
		$self->{tiles} = shift;
	}
	return $self->{tiles};
}


# fill the gacha balls with stdin
sub fill {
	my $self = shift;

	my @balls;
	while (<>) {
		my $ball = Ball->new;
		chomp $_;
		$ball->name($_);
	
		# fill the ball with palettes
		my @palettes;
		for (1..<>) {
			my %palette;
			my $line = <>;
			chomp $line;
			@palette{split /,/, $line} = ();
			push @palettes, \%palette;
		}
		$ball->palettes(\@palettes);
		
		#fill the ball with n sprites
		my @sprites;
		for (1..<>) {
			my $sprite = Sprite->new;
	
			# name the sprite
			my $name = <>;
			chomp $name;
			$sprite->name($name);
			
			# build the sprite with tiles
			my @tiles;
			for (1..<>) {
				my $tile = Tile->new;
				
				# give the tile coordinates
				my ($x, $y) = split /,/, <>;
				chomp $x;
				chomp $y;
				$tile->x($x);
				$tile->y($y);
				
				# assign the tile to one of the palettes
				my $palette= <>;
				chomp $palette;
				$tile->palette($palette);
	
				# get the tile's binary bitplane
				my @bitplane_1 = ();
				for (1..16) {
					my $line = <>;
					chomp $line;
					push @bitplane_1, $line;
				}
				my @bitplane_2 = ();
				for (1..16) {
					my $line = <>;
					chomp $line;
					push @bitplane_2, $line;
				}
				chomp @bitplane_1;
				chomp @bitplane_2;
				
				# turn this into nes binary
				my @bytes;
				push @bytes, splice @bitplane_1, 0, 8;
				push @bytes, splice @bitplane_2, 0, 8;
				push @bytes, splice @bitplane_1, 0, 8;
				push @bytes, splice @bitplane_2, 0, 8;
				
				# give the tile binary data
				$tile->bytes(\@bytes);
				push @tiles, $tile;
			}
	
			# add tile collection to sprite
			$sprite->tiles(\@tiles);
			push (@sprites, $sprite);
		}
	
		# add sprite collection to ball
		$ball->sprites(\@sprites);
		push @balls, $ball;
	}
	$self->balls(\@balls);
}


sub print {
	my $self = shift;
	print "Palettes:\n";
	for my $palette (@{$self->palettes}) {
		for my $color (sort keys %$palette) {
			print $color, " ";
		}
		print "\n";
	}
	for my $tile (@{$self->tiles}) {
		for my $row (@$tile) {
			print $row, "\n";
		}
	}
}


sub publish_label {
	my $self = shift;
	$self->publish_palettes;
	$self->publish_tiles;
}


sub publish_palettes {
	my $self = shift;
	my @palettes;
	for my $ball (@{$self->balls}) {
		for my $palette (@{$ball->palettes}) {
			push @palettes, $palette;
		}
	}
	$self->palettes(\@palettes);
}


sub publish_tiles {
	my $self = shift;
	
	my @sprite_0;
	push @sprite_0, '10000000';
	#(tile height * bit depth) - 1
	for (2..16 * 2) {
		push @sprite_0, '00000000';
	}
	my @tiles;
	push @tiles, \@sprite_0;
	for my $ball (@{$self->balls}) {
		for my $sprite (@{$ball->sprites}) {
			for my $tile (@{$sprite->tiles}) {
				push @tiles, $tile->bytes;
				$tile->reference($#tiles);
			}
		}
	}
	$self->tiles(\@tiles);
}


sub write_palettes {
	my $self = shift;
	print "PALETTES\n";

	# skip zero for null termination
	my $written = 0;

	for my $ball (@{$self->balls}) {
		for my $i (0..$#{$ball->palettes}) {
			printf "%s_PALETTE%02X = \$%02X\n",
				uc $ball->name, $i, ++$written;
			printf "palette%02X:\n", $written;
			print "\t.byte\t";
			my @colors = sort keys %{$ball->palettes->[$i]}; 
			for my $j (0..$#colors) {
				printf "\$%s", $colors[$j];
				if ($j != $#colors) {
					print ", ";
				}
			}
			print "\n\n";
		}
	}
	print "END\n";
}


sub write_sprites {
	my $self = shift;
	my $written = 0;
	print "SPRITES\n";	
	for my $ball (@{$self->balls}) {
		for my $sprite (@{$ball->sprites}) {
			$written++;
			printf "%s = \$%02X\n", uc $sprite->name, $written;
			printf "Sprite%02X:\n", $written;
			for my $tile (@{$sprite->tiles}) {
				printf "\t.lobytes\t";
				printf "\$%02X,\t", ($tile->reference) * 2;
				printf "%3d,\t", $tile->y;
				printf "%3d,\t", $tile->x;
				printf "%%%08b\n", $tile->palette;
			}
			# null terminate
			print "\t.byte\t00\n\n" 
		}
	}
	
	print "Sprites_l:\n";
	print "\t.byte 00\n";
	for my $i (1..$written) {
		printf "\t.byte <Sprite%02X\n",$i;
	}
	print "Sprites_h:\n";
	print "\t.byte 00\n";
	for my $i (1..$written) {
		printf "\t.byte >Sprite%02X\n",$i;
	}
	print "END\n";
}


sub write_tiles {
	my $self = shift;
	print "TILES\n";
	for my $tile (@{$self->tiles}) {
		for my $row (@{$tile}) {
			print "$row\n";
		}
	}
	print "END\n";
}


1;
