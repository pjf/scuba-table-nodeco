use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('Sport::Dive::Tables') };

my $sdt = Sport::Dive::Tables->new();

isnt($sdt,undef,"SDT is defined");
isa_ok($sdt,"Sport::Dive::Tables","Correct class");
can_ok($sdt,"dive","group");
$sdt->dive(metres => 18, minutes => 30);

is($sdt->group,"F","Dive for 18metres for 30 minutes is group F");
