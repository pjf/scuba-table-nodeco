#!/usr/bin/perl

# White box testing.  Don't call these functions in your own code.

use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok("SCUBA::Table::NoDeco"); }

my $stn = SCUBA::Table::NoDeco->new(table => "SSI");

eval { $stn->_std_depth() };
ok($@, "No args should trigger an error.");

is($stn->dive(metres => 18, minutes => 12),"C");
$stn->surface(minutes => 15);

# Let's break a table and make sure it's discovered.
{
	local $SCUBA::Table::NoDeco::SURFACE{SSI}{C} = {};
	eval { $stn->group; };
	like($@, qr/Incomplete table/, "Incomplete table discovered");
}
