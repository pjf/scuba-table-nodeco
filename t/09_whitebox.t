#!/usr/bin/perl

# White box testing.  Don't call these functions in your own code.

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok("SCUBA::Table::NoDeco"); }

my $stn = SCUBA::Table::NoDeco->new(table => "SSI");

eval { $stn->_std() };
ok($@, "No args should trigger an error.");
