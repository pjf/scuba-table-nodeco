use strict;
use warnings;
use Test::More tests => 4;

my @methods = qw(dive group max_time);

BEGIN { use_ok('Sport::Dive::Tables') };

my $sdt = Sport::Dive::Tables->new();

isnt($sdt,undef,"SDT is defined");
isa_ok($sdt,"Sport::Dive::Tables","Correct class");
can_ok($sdt,@methods);
