use Test::More tests => 3;
BEGIN { use_ok('Sport::Dive::Tables') };

my $sdt1 = Sport::Dive::Tables->new();

isa_ok($sdt,"Sport::Dive::Tables","Correct class");

$sdt->dive(metres => 18, minutes => 30);

is($sdt->group,"F","Dive for 18metres for 30 minutes is group F");
