use strict;
use warnings;
use Test::More tests => 5;

my @methods = qw(new list_tables clear table dive group surface max_time rnt);

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new();

isnt($sdt,undef,"SDT is defined");
isa_ok($sdt,"SCUBA::Table::NoDeco","Correct class");
can_ok($sdt,@methods);

ok(eq_set([SCUBA::Table::NoDeco->list_tables()], ["SSI"]));
