#!/usr/bin/env perl

package Sprite;
use strict;
use warnings;

sub new{
	my $class = shift;
	my $name = shift;
	my $pixels = shift;
	my $tile_pixel_width = shift;
	my $tile_pixel_height = shift;
	my $bit_depth = shift;

	my $pixel_width = scalar @{$pixels->[0]};
	my $pixel_height = scalar @{$pixels};
	my $tile_width = $pixel_width / $tile_pixel_width;
	my $tile_height = $pixel_height / $tile_pixel_height;
	my $tile_count = $tile_width * $tile_height;
	my $center_x = $pixel_width / 2;
	my $center_y = $pixel_height / 2;
	my $background_color = $pixels->[0][0];
	my $self = {
		name => $name,
		pixels => $pixels,
		pixel_width => $pixel_width,
		pixel_height => $pixel_height,
		tile_width => $tile_width,
		tile_height => $tile_height,
		tile_count => $tile_count,
		tile_pixel_width => $tile_pixel_width,
		tile_pixel_height => $tile_pixel_height,
		center_x => $center_x,
		center_y => $center_y,
		background_color => $background_color,
		bit_depth => $bit_depth
	};
	bless $self, $class;
	
	# confirm data is valid
	$self->confirm_sprite;

	# shift the sprite around to find best config
	$self->optimize_position;
	# $self->write_resolved_coordinates;

	# shift rows and columns around to find best config
	$self->optimize_tiles;
	# $self->write_optimizations;
	
	# establish the cononical palettes
	$self->publish_palettes;

	if ($self->measure_invalid_tiles){
		die "could not resolve sprite"
	}

	return $self;
};


sub name{
	my $self = shift;
	if (@_) {
		$self->{name} = shift;	
	}
	return $self->{name};
}


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

sub center_x{
	my $self = shift;
	if (@_) {
		$self->{center_x} = shift;	
	}
	return $self->{center_x};
}


sub center_y{
	my $self = shift;
	if (@_) {
		$self->{center_y} = shift;
	}
	return $self->{center_y};
}


sub background_color{
	my $self = shift;
	return $self->{background_color};
}


sub bit_depth{
	my $self = shift;
	return $self->{bit_depth};
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


sub tile_pixel_width{
	my $self = shift;
	return $self->{tile_pixel_width};
}


sub tile_pixel_height{
	my $self = shift;
	return $self->{tile_pixel_height};
}


sub best_offsets_column {
	my $self = shift;
	if (@_) {
		$self->{best_offsets_column} = shift;
	}
	return $self->{best_offsets_column};
}


sub best_offsets_row {
	my $self = shift;
	if (@_) {
		$self->{best_offsets_row} = shift;
	}
	return $self->{best_offsets_row};
}


sub palettes{
	my $self = shift;
	if (@_) {
		$self->{palettes} = shift;
	}
	return $self->{palettes};
}


sub tile_palette{
	my $self = shift;
	my $tile = shift;
	my %palette=();

	#get the top left pixel of the pixel data
	my $tile_x = ($tile 
		% ($self->pixel_width / $self->tile_pixel_width)) 
		* $self->tile_pixel_width;
	my $tile_y = (int($tile 
		/ ($self->pixel_width / $self->tile_pixel_width)))
		* $self->tile_pixel_height;
	#for each pixel row in this tile	
	for my $row ($tile_y..($tile_y + ($self->tile_pixel_height - 1))) {
		#for each pixel in that row
		for my $column ($tile_x..($tile_x + $self->tile_pixel_width)-1) {
			#get the hex color
			my $color = $self->pixels->[$row][$column];
			
			#pop the color in the hash if not background
			$palette{$color}=(1);
		}
	}
	delete %palette{$self->background_color};
	return (\%palette);
}


sub confirm_sprite{
	my $self = shift;
	if ($self->pixel_width % $self->tile_pixel_width){
		die qq(nonstandard tile width);
	}
	if ($self->pixel_height % $self->tile_pixel_height){
		die qq(nonstandard tile height);
	}
	for my $row (@{$self->pixels}){
		if (scalar(@{$row}) != $self->pixel_width){
			die qq(fatal error, tile row found of differing pixels);
		}
	}
}


sub optimize_position{
	my $self = shift;
	my $lowest_invalids = $self->measure_invalid_tiles;
	my $lowest_palettes = $self->measure_palettes;
	my $best_offset_x = 0;
	my $best_offset_y = 0;
	
	#move entire sprite 1 pixel left at a time
	for my $i (1..$self->tile_pixel_width) {
		$self->move_sprite(-1,0);
		
		#count invalid tiles and palettes
		my $invalids = $self->measure_invalid_tiles;
		my $palettes = $self->measure_palettes;
		
		#if this configuration has less bad tiles
		if (($invalids < $lowest_invalids) ||

		# or equal bad tiles and less palettes	
		($invalids == $lowest_invalids &&
		$palettes < $lowest_palettes)) {
			
			#then this is the new best
			$best_offset_x = $i * -1;
			$lowest_invalids = $invalids;
			$lowest_palettes = $palettes;
		}
	}
	#move sprite to the best offset
	$self->move_sprite($self->tile_pixel_width + $best_offset_x, 0);
	
	# move sprite up one tile at a time
	for my $i (1..$self->tile_pixel_height) {
		$self->move_sprite(0,-1);
		
		# measure the palettes and bad tiles
		my $invalids = $self->measure_invalid_tiles;
		my $palettes = $self->measure_palettes;

		# if less bad tiles
		if ($invalids < $lowest_invalids
		
		# or same bad tiles but less palettes	
		||($invalids == $lowest_invalids
		&& $palettes < $lowest_palettes)) {
				
			# this is the new best
			$best_offset_y= $i * -1;
			$lowest_invalids = $invalids;
			$lowest_palettes = $palettes;
		}
	}
	#move to optimal spot
	$self->move_sprite(0, $self->tile_pixel_height + $best_offset_y);
}


sub optimize_tiles{
	my $self = shift;

	# empty collection of best tile count by row and column
	my @best_offsets_row = ();
	my @best_offsets_column = ();
	
	# brute force the the best row configuration by tile
	for my $tile_row (0..$self->tile_height - 1){

		# by default, this is the best configuration... so far
		my $lowest_invalids = $self->measure_invalid_tiles;
		my $lowest_consumed = $self->measure_tiles_used;
		my $lowest_palettes = $self->measure_palettes;
		my $best_offset = 0;
		
		# nudge each tile row to the right, one pixel at a time
		for my $i (1..$self->tile_pixel_width) {
			$self->move_tile_row_horizontal($tile_row, 1);

			# count the tiles used in new configuration
			my $consumed = $self->measure_tiles_used;
			my $invalids = $self->measure_invalid_tiles;
			my $palettes = $self->measure_palettes;
			
			# if this breaks fewer rules
			if ($invalids < $lowest_invalids

			# or breaks the same rules but removes palettes
			|| ($invalids == $lowest_invalids
			&& $palettes < $lowest_palettes)
			
			# or has valids, less or same palettes, less tiles
			|| ($invalids == $lowest_invalids
			&& $palettes <= $lowest_palettes
			&& $consumed < $lowest_consumed)) {
				
				# this is the new best config, congrats!
				$lowest_invalids = $invalids;
				$lowest_consumed = $consumed;
				$lowest_palettes = $palettes;
				$best_offset = $i;
			}
		}
		push(@best_offsets_row, $best_offset);

		#move the the best configuration
		$self->move_tile_row_horizontal($tile_row, 
			-$self->tile_pixel_width + $best_offset);
	}

	# this is the best this configuration can do
	my $lowest_invalids_row = $self->measure_invalid_tiles;
	my $lowest_consumed_row = $self->measure_tiles_used;
	my $lowest_palettes_row = $self->measure_palettes;

	#move the rows back to their original configurations
	for my $tile_row (0..$self->tile_height - 1){
		$self->move_tile_row_horizontal($tile_row,
			$best_offsets_row[$tile_row] * -1);
	}

	# brute force the best column configuration
	for my $tile_column (0..$self->tile_width-1) {
		
		# this is by default the best configuration
		my $lowest_consumed = $self->measure_tiles_used;
		my $lowest_invalids = $self->measure_invalid_tiles;
		my $lowest_palettes = $self->measure_palettes;
		my $best_offset = 0;

		# move the columns down one pixel at a time
		for my $i (1..$self->tile_pixel_height) {
			$self->move_tile_column_vertical($tile_column, 1);

			# count the bad tiles, palettes, and tiles used
			my $consumed = $self->measure_tiles_used;
			my $invalids = $self->measure_invalid_tiles;
			my $palettes = $self->measure_palettes;

			# if this breaks fewer rules
			if ($invalids < $lowest_invalids

			# or breaks the same rules but less palettes
			|| ($invalids == $lowest_invalids
			&& $palettes < $lowest_palettes)
			
			# or is resolved, same or less palettes, less tiles
			|| ($invalids == $lowest_invalids
			&& $palettes <= $lowest_palettes
			&& $consumed < $lowest_consumed)) {

			# this is the new best one! congrats!
				$lowest_invalids = $invalids;
				$lowest_consumed = $consumed;
				$lowest_palettes = $palettes;
				$best_offset = $i;
			}
		}
		# save this configuration for later
		push(@best_offsets_column, $best_offset);
		
		# move to the optimal position
		$self->move_tile_column_vertical($tile_column, 
			-$self->tile_pixel_height + $best_offset);
	}
	
	# this is the best this configuration can do
	my $lowest_consumed_column = $self->measure_tiles_used;
	my $lowest_invalids_column = $self->measure_invalid_tiles;
	my $lowest_palettes_column = $self->measure_palettes;
	
	
	# move the columns back to their original configurations
	for my $tile_column (0..$self->tile_width - 1){
		$self->move_tile_column_vertical($tile_column,
			$best_offsets_column[$tile_column] * -1);
	}
	
	# if rows had the fewest bad tiles
	if ($lowest_invalids_row < $lowest_invalids_column

	# or had the same bad tiles but lower palettes
	|| ($lowest_invalids_row == $lowest_invalids_column
	&& $lowest_palettes_row < $lowest_palettes_column)

	# or had same bad, same palettes, but lower tile count
	|| ($lowest_invalids_row == $lowest_invalids_column
	&& $lowest_palettes_row == $lowest_palettes_column
	&& $lowest_consumed_row < $lowest_consumed_column)

	# or were all equal because tie breaker
	|| ($lowest_invalids_row == $lowest_invalids_column
	&& $lowest_palettes_row == $lowest_palettes_column
	&& $lowest_consumed_row == $lowest_consumed_column)) {
		
		# move it to the row configuration
		for my $tile_row (0..$self->tile_height - 1){
			$self->move_tile_row_horizontal($tile_row,
				$best_offsets_row[$tile_row]);
		}
		# save the offsets and set other as false
		$self->best_offsets_row(\@best_offsets_row);
		$self->best_offsets_column(0);
	} else {
		for my $tile_column (0..$self->tile_width - 1){
			$self->move_tile_column_vertical($tile_column,
				$best_offsets_column[$tile_column]);
		}
		# save the offsets and set other as false
		$self->best_offsets_column(\@best_offsets_column);
		$self->best_offsets_row(0);
	}
}


sub measure_invalid_tiles{
	my $self = shift;
	my $invalid_count = 0;# count of invalid tiles
	for my $tile (0..$self->tile_count-1) {
		# if tile is invalid 
		if (!$self->is_tile_valid($tile)) {
			$invalid_count++;
		}
	}
	return $invalid_count;
}


sub measure_palettes{
	my $self = shift;
	my ($valids, $invalids) = $self->get_palettes;
	my $total = scalar(@$valids) + scalar(@$invalids);
	return $total;
}


sub get_palettes{
	my $self = shift;
	my @valids;
	my @invalids;
	# get all the palettes
	for my $tile (0..$self->tile_count-1) {
		my $palette = $self->tile_palette($tile);
		# if within bitdepth add to valid collection
		if(scalar %{$palette} < (2 ** $self->bit_depth)) {
			push(@valids, $palette);

		# else add to invalid collection
		} else {
			push(@invalids, $palette);
		}
	}
	#pull of each palette one by one
	for my $i (0..$#valids) {
		my $test_palette = shift(@valids);

		#clear the duplicate flag
		my $duplicate = 0;

		#compare to the rest of the palettes
		for my $palette (@valids) {

			#make a collection of matching colors
			my @matches = ();
			for my $color (keys %{$test_palette}) {
				if (exists $palette->{$color}) {
				push(@matches, $color);
				}
			}
			# if all colors are matches, duplicate
			if (scalar %{$test_palette} == scalar @matches) {
				$duplicate = 1;
				last;
			}
		}
		# if original, save
		if (!$duplicate) {
			push(@valids, $test_palette);
		}
	}
	
	#pull of each palette one by one
	for my $i (0..$#invalids) {
		my $test_palette = shift(@invalids);

		# clear the duplicate flag
		my $duplicate = 0;

		#compare to the rest of the palettes
		for my $palette (@invalids) {

			# test all colors
			my @matches = ();
			for my $color (keys %{$test_palette}) {
				# if color in other palette
				if (exists $palette->{$color}) {
					# add to collection
					push(@matches, $color);
				}	
			}
			# if every color is in another palette
			if (scalar %{$test_palette} == scalar @matches) {
				
				# it is a duplicate
				$duplicate = 1;
				last;
			}
		}
		# if it's not a duplicate
		if (!$duplicate) {
			# save it as a unique
			push(@invalids, $test_palette);
		}
	}
	return (\@valids, \@invalids);
}


sub is_tile_valid{
	my $self = shift;
	my $tile = shift;
	# get palette
	my $palette = $self->tile_palette($tile);
	# if within bit depth
	if ((scalar %{$palette}) < (2 ** $self->bit_depth)){
		return 1;
	}
	return 0;
}

sub measure_tiles_used{
	my $self = shift;
	my $used = 0;
	for my $tile (0..$self->tile_count-1) {
		if ($self->is_tile_used($tile)) {
			$used++;
		}
	}
	return $used;
}


sub is_tile_used{
	my $self = shift;
	my $tile = shift;
	# get palette
	my $palette = $self->tile_palette($tile);
	
	# if 1 or more color (excluding background)
	if (scalar %{$palette}) {
		return 1;
	}
	return 0;
}


sub move_sprite{
	my $self = shift;
	my $x_movements = shift;
	my $y_movements = shift;
	
	$self->move_sprite_horizontal($x_movements);
	$self->move_sprite_vertical($y_movements);
}


sub move_sprite_horizontal{
	my $self = shift;
	my $x_movements = shift;
	#if moving left
	if ($x_movements < 0) {
		#cut off the front of every row and append it
		for my $row (@{$self->pixels}) {
			push(@{$row},
				splice(@{$row}, 0, $x_movements * -1));
		}
	}
	#if moving right
	if ($x_movements > 0) {
		#cut off the end of every row and prepend it
		for my $row (@{$self->pixels}) {
			unshift(@{$row},
				splice(@{$row}, $x_movements * -1));
		}
	}
	$self->center_x($self->center_x + $x_movements);
}


sub move_sprite_vertical{
	my $self = shift;
	my $y_movements = shift;
	#if moving up
	if ($y_movements < 0) {
		#cut off the top rows and append it
		push(@{$self->pixels},
			splice(@{$self->pixels}, 0, $y_movements * -1));
	}
	#if moving down 
	if ($y_movements > 0) {
		#cut off the bottom rows and prepend them
		unshift(@{$self->pixels},
			splice(@{$self->pixels}, $y_movements * -1));
	}
	$self->center_y($self->center_y + $y_movements);
}


sub move_tile_row_horizontal{
	my $self = shift;
	my $tile_row = shift;
	my $x_movements = shift;
	
	my $pixel_row_start = $tile_row * $self->tile_pixel_height;
	my $pixel_row_end = ($tile_row * $self->tile_pixel_height) + ($self->tile_pixel_height - 1);

	#if moving left
	if ($x_movements < 0) {
		#cut off the front of every row and append it
		for my $i ($pixel_row_start..$pixel_row_end) {
			my $pixel_row = @{$self->pixels}[$i];
			push(@{$pixel_row},
				splice(@{$pixel_row}, 
					0, $x_movements * -1));
		}
	}
	#if moving right
	if ($x_movements > 0) {
		#cut off the end of every row and prepend it
		for my $i ($pixel_row_start..$pixel_row_end) {
			my $pixel_row = @{$self->pixels}[$i];
			unshift(@{$pixel_row}, 
				splice(@{$pixel_row}, $x_movements * -1));
		}
	}
}


sub move_tile_column_vertical {
	my $self = shift;
	my $tile_column = shift;
	my $y_movements = shift;
	my @replacement_pixel_buffer = ();
	my $pixel_column_start = $tile_column * $self->tile_pixel_width;
	my $pixel_column_end = $pixel_column_start 
			+ ($self->tile_pixel_width - 1);

	#replace the segment of the row with the one above or below
	for my $pixel_row (0..$#{$self->pixels}) {
		my $next_row = ($pixel_row - $y_movements)
			% (scalar @{$self->pixels});
		my $replacement_row = $self->pixels->[$next_row];
		my @replacement_pixels = @$replacement_row
			[$pixel_column_start..$pixel_column_end];
		push (@replacement_pixel_buffer, \@replacement_pixels);
	}
	for my $pixel_row (0..$#{$self->pixels}) {
		splice(@{$self->pixels->[$pixel_row]}, 
			$pixel_column_start, $self->tile_pixel_width, 
			@{$replacement_pixel_buffer[$pixel_row]});
	}
}


sub publish_palettes {
	my $self = shift;
	
	# get all the valid palettes
	my $palettes = ($self->get_palettes)[0];

	# make place for published palette
	my @finals = ();
	
	# take every palette, assign number to the keys from light to dark
	for my $palette (@$palettes) {
		my $count = 0;
		my $final = {};
		for my $color (sort keys %{$palette}) {
			$final->{$color} = ++$count;
		}
		# add to the final palette
		push @finals, $final;
	}
	# publish it
	$self->palettes(\@finals);
}


sub write_name{
	my $self = shift;
	printf "Name\t\t%s\n", $self->name;
}


sub write_background {
	my $self = shift;
	printf "Background\t%s\n", $self->background_color;
}


sub write_palettes {
	my $self = shift;
	my $offset = shift;
	
	printf "Palettes\t%s\n", scalar @{$self->palettes};
	# for every palette
	my $palettes_written = 0;
	for my $palette (@{$self->palettes}) {

		# print numerical label
		printf "  Palette%02X:\t", ($palettes_written + $offset);

		#for every color
		my $colors_written = 0;
		for my $color (sort keys %$palette) {

			# if not the last color, print comma. else new line
			if(++$colors_written != scalar %$palette) {
				print $color,",";
			} else {
				print $color,"\n";
			}
		}
		$palettes_written++;
	}
}


sub write_tiles {
	my $self = shift;
	my $bitplane = shift;
	my $offset = shift;
	
	printf "Tiles\t\t%d\n", $self->measure_tiles_used;
	
	# loop through tile collection, process if active
	my $tiles_written = 0;
	for my $tile (0..$self->tile_count-1) {
		if ($self->is_tile_used($tile)) {
			
			# print name, coordinates, pixels
			printf "  Tile%02X\t", $tiles_written++;
			
			my ($x, $y) = $self->get_tile_coordinates($tile);
			printf "%d,%d\n", $x,$y;
			my $reference = $self->get_palette_reference($tile);
			printf "  Palette\t%02d\n", ($offset + $reference);

			if ($bitplane) {
				$self->write_bitplanes($tile,$reference);
			} else {
				$self->write_references($tile,$reference);
			}
		}
	}
}


sub write_bitplanes{
	my $self = shift;
	my $tile = shift;
	my $reference = shift;
	my $palette = $self->palettes->[$reference];
	
	#get the top left pixel of the pixel data
	my $tile_x = ($tile % $self->tile_width) * $self->tile_pixel_width;
	my $tile_y = int($tile / $self->tile_width) 
			* $self->tile_pixel_height;
	
	for my $plane (0..$self->bit_depth-1) {
		printf "  plane%d\t",$plane;

	#for each pixel row in this tile	
		for my $row ($tile_y..($tile_y 
				+ ($self->tile_pixel_height-1))) {

			
			# dont print dot on new line
			if ($row % $self->tile_pixel_height) {
				print "  .\t\t";
			}

			# go through pixels in row
			for my $column ($tile_x..($tile_x 
					+ ($self->tile_pixel_width-1))) {
				
				#fetch the color, then the reference
				my $color = $self->pixels->[$row][$column];
				my $reference = $palette->{$color};

				# if not the background color, print bit
				if ($reference) {
					my $bit = ($reference >> $plane)&1;
					print $bit;
				} else {
					print 0;
				}
			}
			print "\n";
		}
	}
}


sub write_references{
	my $self = shift;
	my $tile = shift;
	my $reference = shift;
	my $palette = $self->palettes->[$reference];
	
	#get the top left pixel of the pixel data
	my $tile_x = ($tile % $self->tile_width) * $self->tile_pixel_width;
	my $tile_y = int($tile / $self->tile_width) 
			* $self->tile_pixel_height;
	
	#for each pixel row in this tile	
	for my $row ($tile_y..($tile_y+($self->tile_pixel_height-1))) {
		
		# print dots for the rows
		print "  .\t\t";

		# go through pixels in row
		for my $column ($tile_x..($tile_x
				+ ($self->tile_pixel_width-1))) {
			
			#fetch the color, then the reference
			my $color = $self->pixels->[$row][$column];
			my $reference = $palette->{$color};

			# if not the background color, print bit
			if ($reference) {
				if ($self->bit_depth > 4) {
					printf "%02X", $reference;
				} else {
					printf "%x", $reference;
				}
			} else {
				if ($self->bit_depth > 4) {
					print "00";
				} else {
					print "0";
				}
			}
		}
		print "\n";
	}
}


sub get_palette_reference{
	my $self = shift;
	my $tile = shift;
	
	# compare against every master palette
	for my $i (0..$#{$self->palettes}) {
		my $palette = $self->tile_palette($tile);
		my $reference = $self->palettes->[$i];
		my $size = scalar %$reference;
		for my $color (keys %{$self->palettes->[$i]}) {
			$palette->{$color} = 1;
		}
		if (scalar(%$palette) == $size){
			return $i;
		}
	}
}


sub get_tile_coordinates{
	my $self = shift;
	my $tile = shift;

	# get the base coordinates, the top left
	my $tile_x = ($tile % ($self->pixel_width / $self->tile_pixel_width)) 
		* $self->tile_pixel_width;
	my $tile_y = (int($tile / ($self->pixel_width / $self->tile_pixel_width)))
		* $self->tile_pixel_height;
	
	# adjust the coordinates based on the actual center of the sprite
	$tile_x = $tile_x - $self->center_x;
	$tile_y = $tile_y - $self->center_y;
	
	# if it was compressed by row, 
	if ($self->best_offsets_row) {
		
		# find the optimization for this tile
		my $optimization_offset = int(
			$tile / $self->tile_width);
		my $optimizations = $self->best_offsets_row;

		# account for the optimization
		$tile_x = $tile_x - $optimizations->[$optimization_offset];
	}

	# if it was compressed by column 
	if ($self->best_offsets_column) {
		
		# find the optimization for this tile
		my $optimization_offset = $tile % $self->tile_width;
		my $optimizations = $self->best_offsets_column;

		# account for the optimization
		$tile_y = $tile_y - $optimizations->[$optimization_offset];
	}
	return ($tile_x, $tile_y);
}


sub write_pixels {
	my $self = shift;

	for my $pixel_row (@{$self->pixels}) {
		print @{$pixel_row};
		print "\n";
	}
}


sub write_optimizations{
	my $self = shift;

	if ($self->best_offsets_row) {
		printf "row won with\t%2d\n", $self->measure_tiles_used;
		print @{$self->best_offsets_row},"\n";
	}
	if ($self->best_offsets_column) {
		printf "column won with\t%2d\n", $self->measure_tiles_used;
		print @{$self->best_offsets_column},"\n";
	}
}


sub write_resolved_coordinates {
	my $self = shift;

	# goot test data
	print "resolved at: \tx: ";
	print $self->center_x - ($self->pixel_width / 2);
	print "\ty: ";
	print $self->center_y - ($self->pixel_height / 2);
	print "\n";
}


1;
