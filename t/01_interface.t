use strict;
use warnings;
use Test::More tests => 4;

my @methods = qw(dive group max_time surface clear rnt);

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new();

isnt($sdt,undef,"SDT is defined");
isa_ok($sdt,"SCUBA::Table::NoDeco","Correct class");
can_ok($sdt,@methods);
