#!/usr/bin/perl -w
use strict;
use Test::More tests => 19;

# Tests specific to the PADI tables.  I only have a copy of these
# in feet, hence all the tests are in feet as well.  This is good,
# since the module uses metres internally.

BEGIN { use_ok("SCUBA::Table::NoDeco"); }

my $sdt = SCUBA::Table::NoDeco->new(table => "PADI");

is($sdt->table,"PADI","Using correct tables");

# Boundry cases in table.

is($sdt->dive(feet => 110, minutes => 13),"I"); $sdt->clear;
is($sdt->dive(feet => 110, minutes => 14),"K"); $sdt->clear;

is($sdt->dive(feet => 120, minutes => 11),"H"); $sdt->clear;
is($sdt->dive(feet => 120, minutes => 12),"J"); $sdt->clear;

is($sdt->dive(feet => 130, minutes =>  7),"D"); $sdt->clear;
is($sdt->dive(feet => 130, minutes =>  8),"F"); $sdt->clear;

foreach (1..4) {
	is($sdt->dive(feet => 140, minutes =>  $_),"B"); $sdt->clear;
}

# Some typical dive profiles.  These are by no means comprehensive
# tests.

is($sdt->dive(feet => 20, minutes => 32),"E");
$sdt->surface(minutes => 39);
is($sdt->group,"B");
is($sdt->max_time(feet => 50),67);
is($sdt->rnt(feet => 60), 11);

is($sdt->dive(feet => 60, minutes => 40),"U","Second dive in series");
$sdt->surface(minutes => 29);
is($sdt->group,"N");
