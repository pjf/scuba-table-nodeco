#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3+16+16;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

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

my %MAX_TIMES_FT = (
	10  => 300,
	15  => 350,
	20  => 325,
	25  => 245,
	30  => 205,
	35  => 160,
	40  => 130,
	50  =>  70,
	60  =>  50,
	70  =>  40,
	80  =>  30,
	90  =>  25,
	100 =>  20,
	110 =>  15,
	120 =>  10,
	130 =>   5,
);

my $sdt = SCUBA::Table::NoDeco->new();

$sdt->dive(metres => 18, minutes => 30);

is($sdt->group,"F","Dive for 18 metres for 30 minutes is group F");
$sdt->clear;

is($sdt->group,"","Group cleared");

foreach my $depth (keys %MAX_TIMES) {
	is($sdt->max_time(metres => $depth), $MAX_TIMES{$depth},
	   "Max time at $depth metres is $MAX_TIMES{$depth}");
}

foreach my $depth (keys %MAX_TIMES_FT) {
	is($sdt->max_time(feet => $depth), $MAX_TIMES_FT{$depth},
	   "Max time at $depth feet is $MAX_TIMES_FT{$depth}");
}

TODO: {
	local $TODO = "Unimplemented error-checking";
};
