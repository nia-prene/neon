#!/usr/bin/env perl

use strict;
use warnings;

package Sprite;

sub new {
	my $class = shift;
	return bless {}, $class;
}


sub name {
	my $self = shift;
	if (@_) {
		$self->{name} = shift;
	}
	return $self->{name};
}


sub tiles {
	my $self = shift;
	if (@_) {
		$self->{tiles} = shift;
	}
	return $self->{tiles};
}


1;
