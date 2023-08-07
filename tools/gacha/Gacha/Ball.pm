#!/usr/bin/env perl

use strict;
use warnings;

package Ball;

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


sub palettes {
	my $self = shift;
	if (@_) {
		$self->{palettes} = shift;
	}
	return $self->{palettes};
}


sub palette_references {
	my $self = shift;
	if (@_) {
		$self->{palette_references} = shift;
	}
	return $self->{palette_references};
}


sub sprites {
	my $self = shift;
	if (@_) {
		$self->{sprites} = shift;

	}
	return $self->{sprites};
}


;1
