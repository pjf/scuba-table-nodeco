#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 18;

BEGIN { use_ok('Sport::Dive::Tables') };

my %MAX_TIMES = (
	3.0  => 300,
	4.5  => 350,
	6.0  => 325,
	7.5  => 245,
	9.0  => 205,
	10.5 => 160,
	12.0 => 130,
	15.0 =>  70,
	18.0 =>  50,
	21.0 =>  40,
	24.0 =>  30,
	27.0 =>  25,
	30.0 =>  20,
	33.0 =>  15,
	36.0 =>  10,
	39.0 =>   5,
);

my $sdt = Sport::Dive::Tables->new();

$sdt->dive(metres => 18, minutes => 30);

is($sdt->group,"F","Dive for 18metres for 30 minutes is group F");

foreach my $depth (keys %MAX_TIMES) {
	is($sdt->max_time(metres => $depth), $MAX_TIMES{$depth},
	   "Max time at $depth metres is $MAX_TIMES{$depth}");
}

TODO: {
	local $TODO = "Unimplemented error-checking";
};