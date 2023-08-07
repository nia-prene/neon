#!/usr/bin/env perl

use strict;
use warnings;

package Tile;

sub new {
	my $class = shift;
	return bless {}, $class;
}


sub x {
	my $self = shift;
	if (@_) {
		$self->{x} = shift;
	}
	return $self->{x};
}


sub y {
	my $self = shift;
	if (@_) {
		$self->{y} = shift;
	}
	return $self->{y};
}


sub palette {
	my $self = shift;
	if (@_) {
		$self->{palette} = shift;
	}
	return $self->{palette};
}


sub bytes {
	my $self = shift;
	if (@_) {
		$self->{bytes} = shift;
	}
	return $self->{bytes};
}


sub reference {
	my $self = shift;
	if (@_) {
		$self->{reference} = shift;
	}
	return $self->{reference};
}


;1
