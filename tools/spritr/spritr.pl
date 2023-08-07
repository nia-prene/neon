#!/usr/bin/env perl
#converts images to metasprites
use strict;
use warnings;
use diagnostics;
use autodie;


use FindBin;
use lib "$FindBin::Bin/";

use Getopt::Long;
use File::Basename;
use Spritr::Sprite;

my $target = 'nes';
my $size = 0;
my $depth = 0;
my $group = '';
my $join = '';
my $bitplane = '';
my $offset = 0;

GetOptions (
	'size=s' => \$size,
	'depth=i' => \$depth,
	'bitplane' => \$bitplane,
	'offset=i' => \$offset,
	'join' => \$join,
	'group=s' => \$group,
	'target=s' => \$target
);

if ($target =~ m/^nes/) {
	if (!$size) {$size = '8x8'}
	if (!$depth) {$depth = 2}
}
if ($target =~ m/^snes/) {
	if (!$size) {$size = '8x8'}
	if (!$depth) {$depth = 4}
}
my ($tile_width, $tile_height) = split /[^0-9]+/, $size;


my @sprites = ();
# for every file passed
for my $file (@ARGV) {
	
	# name the sprite based off the file name
	my $name = (fileparse($file, qr/\.[^.]*/))[0];
	
	# get the images dimension
	my $dimensions =`identify $file | awk '{print \$3}'`;
	chomp $dimensions;
	my ($width, $height) = split ("x",$dimensions);
	
	# get the hex rgb values of unique colors in the image
	my @colors = `convert $file -format %c histogram:info: \\
		| awk '{print \$3}'`;
	chomp @colors;

	# turn those colors into a conversion hash for the target console
	my %conversions = ();
	for my $color (@colors) {
		if ($target =~ m/^snes/) {
			$conversions{$color} = convert_to_snes($color);
		}
		if ($target =~ m/^nes/) {
			$conversions{$color} = convert_to_nes($color);
		}
		if ($target =~ m/^hex/) {
			if (!$size) { 
				$tile_width = $width;
				$tile_height = $height;
			}
			if (!$depth) {
				if (scalar (@colors) > 256) {
					die "colors exceed 256";
				}
				if (scalar (@colors) > 16) {
					$depth = 8;
				} else { 
					$depth = 4;
				}
			}
			$conversions{$color} = "$color";
		}
	}

	# get all pixels, removing the column header
	my @pixels =`convert $file txt:- | awk '{print \$3}' | sed 1d`;
	chomp @pixels;

	my $pixel_lattice = [];
	my $pixel_row = [];

	#convert every pixel, and add it to the pixel row
	for my $i (0..$#pixels) {
		push @{$pixel_row}, $conversions{$pixels[$i]};
	
		# if the end of a row, add it to lattice and make new row
		if (!(($i + 1) % $width)) {
			push @$pixel_lattice, $pixel_row;
			$pixel_row = [];
		}
	}
	# make a new sprite out of this image and add to collection
	push @sprites, Sprite->new(
		$name, $pixel_lattice, $tile_width, $tile_height, $depth);
}

# if palettes are joined, make a combined palette and assign to all
if ($join || $group) {
	my @palettes= ();
	for my $sprite (@sprites) {
		for my $palette (@{$sprite->palettes}) {
			push @palettes, $palette;
		}
	}
	for my $i (0..$#palettes) {
		my $test = shift @palettes;
		my $repeat = 0;
		for my $palette (@palettes) {
			my @uniques = grep { 
					!exists $palette->{$_} 
					} keys %$test;
				
			#if no unique colors, cut out palette
			if (!@uniques) {
				$repeat = 1;
				last;
			}
		}
		if (!$repeat) {
			push @palettes, $test;
		}
	}
	for my $sprite (@sprites) {
		$sprite->palettes(\@palettes);
	}
}

if ($group) {
	printf "Group\t\t%s\n", $group;
	$sprites[0]->write_palettes($offset);
	printf "Sprites\t\t%d\n", scalar @sprites;
	for my $sprite (@sprites) {
		$sprite->write_name;
		$sprite->write_tiles($bitplane, $offset);
	}
} else {
	for my $sprite (@sprites) {
		$sprite->write_name;
		$sprite->write_palettes($offset);
		$sprite->write_tiles($bitplane, $offset);
	}
}


sub convert_to_nes{
	my $hex = shift;
	
	my $red = hex(substr($hex, 1, 2));
	my $green = hex(substr($hex, 3, 2));
	my $blue = hex(substr($hex, 5, 2));
	
	my %palette = (
		"7C7C7C" => "00",
		"0000FC" => "01",
		"0000BC" => "02",
		"4428BC" => "03",
		"940084" => "04",
		"A80020" => "05",
		"A81000" => "06",
		"881400" => "07",
		"503000" => "08",
		"007800" => "09",
		"006800" => "0A",
		"005800" => "0B",
		"004058" => "0C",
		"000000" => "0F",
		"000000" => "0F",
		"000000" => "0F",
		"BCBCBC" => "10",
		"0078F8" => "11",
		"0058F8" => "12",
		"6844FC" => "13",
		"D800CC" => "14",
		"E40058" => "15",
		"F83800" => "16",
		"E45C10" => "17",
		"AC7C00" => "18",
		"00B800" => "19",
		"00A800" => "1A",
		"00A844" => "1B",
		"008888" => "1C",
		"000000" => "0F",
		"000000" => "0F",
		"000000" => "0F",
		"F8F8F8" => "20",
		"3CBCFC" => "21",
		"6888FC" => "22",
		"9878F8" => "23",
		"F878F8" => "24",
		"F85898" => "25",
		"F87858" => "26",
		"FCA044" => "27",
		"F8B800" => "28",
		"B8F818" => "29",
		"58D854" => "2A",
		"58F898" => "2B",
		"00E8D8" => "2C",
		"787878" => "2D",
		"000000" => "0F",
		"000000" => "0F",
		"FCFCFC" => "30",
		"A4E4FC" => "31",
		"B8B8F8" => "32",
		"D8B8F8" => "33",
		"F8B8F8" => "34",
		"F8A4C0" => "35",
		"F0D0B0" => "36",
		"FCE0A8" => "37",
		"F8D878" => "38",
		"D8F878" => "39",
		"B8F8B8" => "3A",
		"B8F8D8" => "3B",
		"00FCFC" => "3C",
		"F8D8F8" => "3D",
		"000000" => "0F",
		"000000" => "0F"
	);
	
	my $closest_color = "";
	my $closest_distance = (2*(255 ** 2))+(3*(255 ** 2))+(2*(255 ** 2));
	for my $reference (keys %palette) {
		my $reference_red = hex(substr($reference, 0, 2));
		my $reference_green = hex(substr($reference, 2, 2));
		my $reference_blue = hex(substr($reference, 4, 2));

		my $red_delta = $red - $reference_red;
		my $green_delta = $green - $reference_green;
		my $blue_delta = $blue - $reference_blue;

		my $distance_red = 2 * ($red_delta ** 2);
		my $distance_green = 3 * ($green_delta ** 2);
		my $distance_blue = 2 * ($blue_delta ** 2);

		my $distance = $distance_red+$distance_green+$distance_blue;
		if ($distance < $closest_distance) {
			$closest_distance = $distance;
			$closest_color = $reference;
		}
	}
	return $palette{$closest_color};
}


sub convert_to_snes{
	my $hex = shift;
	
	my $red = hex(substr($hex, 1, 2));
	my $green = hex(substr($hex, 3, 2));
	my $blue = hex(substr($hex, 5, 2));
	
	$red = $red / 8;
	$green = $green / 8; 
	$blue = $blue / 8;
	
	$blue = $blue * 1024;
	$green = $green * 32;
	my $decimal = $blue + $green + $red;
	
	my $color = sprintf("%04X", $decimal);
	return $color;
}
