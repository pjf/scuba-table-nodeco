package Sport::Dive::Tables;

use strict;
use warnings;
use Carp;

our $VERSION = "0.01";

# There's really 0.3048 feet in a metre, but all the dive tables seem
# to assume a flat 1 ft = 30 cm.  As such, we use the same constant here,
# otherwise we end up with incorrect results.

use constant FEET2METRES => 0.3;

my %LIMITS = (
    SSI => {
         3.0    => [60, 120, 210, 300],
         4.5    => [35,  70, 110, 160, 225, 350],
	 6.0    => [25,  50,  75, 100, 135, 180, 240, 325],
	 7.5    => [20,  35,  55,  75, 100, 125, 160, 195, 245],
	 9.0    => [15,  30,  45,  60,  75,  95, 120, 145, 170, 205],
	10.5    => [ 5,  15,  25,  40,  50,  60,  80, 100, 120, 140, 160],
	12.0    => [ 5,  15,  25,  30,  40,  50,  70,  80, 100, 110, 130],
	15.0    => [ 0,  10,  15,  25,  30,  40,  50,  60,  70],
	18.0    => [ 0,  10,  15,  20,  25,  30,  40,  50],
	21.0    => [ 0,   5,  10,  15,  20,  30,  35,  40],
	24.0    => [ 0,   5,  10,  15,  20,  25,  30],
	27.0    => [ 0,   5,  10,  12,  15,  20,  25],
	30.0    => [ 0,   5,   7,  10,  15,  20],
	33.0    => [ 0,   0,   5,  10,  13,  15],
	36.0    => [ 0,   0,   5,  10],
	39.0    => [ 0,   0,   5]
    },
);

# Which depths appear on the charts, in numerically ascending order.
my %DEPTHS = (
	SSI => [sort {$a <=> $b} keys %{$LIMITS{SSI}}],
);

sub new {
	my $class = shift;
	my $this = {};
	bless($this,$class);
	$this->_init(@_);
	return $this;
}

sub _init {
	my ($this, %args) = @_;
	$this->{table}   = $args{table}   || "SSI"; # Tables to use.
	$this->{group}   = $args{group}   || "";    # Initial group.
	$this->{surface} = $args{surface} || 0;     # Surface time.
	$this->{bent}    = "";                      # Are we bent/reason?
	return $this;
}

sub group { return $_[0]->{group}; }

sub dive {
	my ($this, %args) = @_;

	# Argument checking.  Yawn.

	$args{minutes} or croak "Missing mandatory 'minutes' parameter to Sport::Dive::Tables::dive";
	if ($args{feet} and $args{metres}) {
		croak "Both feet and metres arguments supplied to Sport::Dive::Tables";
	} elsif ($args{feet}) {
		$args{metres} = $args{feet} * FEET2METRES;
	} elsif (not $args{metres}) {
		croak "Missing mandatory 'feet' or 'metres' parameter to Sport::Dive::Tables::dive";
	}

	# Calculate group.  This is done by looping over the list
	# of depths until we find one equal to or greater than our
	# current dive depth.

	my $group = "A";

	foreach my $depth (@{$DEPTHS{$this->{table}}}) {
		if ($depth >= $args{metres}) {
			foreach my $time (@{$LIMITS{$this->{table}}{$depth}}) {
				# Now walk through all our groups until
				# we find one with a time equal to or
				# greater than our current time.
				# XXX - Compensate for residual N2 here.

				if ($time >= $args{minutes}) {
					$this->{group} = $group;
					return $group;
				}
				$group++;
			}
			$this->{bent} = "$args{minutes} exceeds maximum no-decompression time for a dive to $args{metres} metres.";
			return;
		}
	}
	$this->{bent} = "Depth $args{metres} metres not available on $this->{table} table.";
	return;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sport::Dive::Tables - Calculate no-decompression dive times.

=head1 SYNOPSIS

  use Sport::Dive::Tables;

  my $table = Sport::Dive::Tables->new();

  $table->dive(metres => 15, minutes => 30);

  print $table->group,"\n";	# Prints "E"

  $table->surface(minutes => 60);

  print $table->group,"\n";	# Prints "D"

  print $table->max_time(metres => 30),"\n";	# Prints 6

=head1 WARNING AND DISCLAIMER

Do B<NOT> use this module as your sole source of no-decompression
dive times.  This module is intended for use only as a guide to
planning your guides.  B<ALWAYS> calculate and verify your dive times
by hand once you have planned your dives.  If you have a dive computer,
follow its instructions for use.

SCUBA diving involves serious risks of injury or death, and should
only be performed by individuals in good health and with the appropriate
skills and training.  Even when tables are used with proper safety
procedures, decompression sickness may still occur.

The author provides ABSOLUTELY NO WARRANTY on this module, without
even the implied warranty of merchantability or fitness for a particular
purpose.  Use entirely at your own risk.

=head1 DESCRIPTION


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Paul Fenwick, E<lt>pjf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Paul Fenwick.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
