#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/";

use Gacha::Ball;
use Gacha::Sprite;
use Gacha::Tile;
use Gacha::Gacha;

my $gachapon = Gacha->new;
$gachapon->fill;
$gachapon->publish_label;
$gachapon->write_sprites;
$gachapon->write_palettes;
$gachapon->write_tiles;
