#!/usr/bin/perl

# Test a series of repetitive dives.

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok('Sport::Dive::Tables') };

my $sdt = Sport::Dive::Tables->new(table => "SSI");

# Dives from PJF's logbook, #3-#6

$sdt->dive(metres => 16.1, minutes => 23);
is($sdt->group,"E");

$sdt->surface(minutes => 3*60+17);
is($sdt->group,"C");
is($sdt->rnt(metres => 10.1), 25);
$sdt->dive(metres => 10.1, minutes => 34);
is($sdt->group,"E");

$sdt->surface(minutes => 3*60+34);
is($sdt->group,"C");
is($sdt->rnt(metres => 11.5),25);
$sdt->dive(metres => 11.5, minutes => 33);
is($sdt->group,"G");

$sdt->surface(minutes => 2*60+20);
is($sdt->group,"D");
is($sdt->rnt(metres => 10.2), 37);
$sdt->dive(metres => 10.2, minutes => 30);
is($sdt->group,"G");

