package Sport::Dive::Tables;

use strict;
use warnings;
use Carp;

our $VERSION = "0.01";

# There's really 0.3048 feet in a metre, but all the dive tables seem
# to assume a flat 1 ft = 30 cm.  As such, we use the same constant here,
# otherwise we end up with incorrect results.

use constant FEET2METRES => 0.3;

# Less than 10 minutes surface is considered part of the same dive.
# TODO - Create a test that checks < 10 minute surface dives.
use constant MIN_SURFACE_TIME => 10;

# More than MAX_SURFACE_TIME will consider us completely off-gassed.
use constant MAX_SURFACE_TIME => 12*60;

our %LIMITS = (
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
our %DEPTHS = (
	SSI => [sort {$a <=> $b} keys %{$LIMITS{SSI}}],
);

our %SURFACE = (
    SSI => {
        A => { 12*60 => "A" },
	B => { 12*60 => "A", 3*60+20 => "B" },
	C => { 12*60 => "A", 4*60+49 => "B", 1*60+39 => "C" },
	D => { 12*60 => "A", 5*60+48 => "B", 2*60+38 => "C", 1*60+9 => "D" },
	# TODO, Finiish for E-K.
    },
);

our %RESIDUAL = (
	SSI => {
		 3 => [39, 88, 159, 279],
		 6 => [18, 39,  62,  88, 120, 159, 208, 279, 399],
		 9 => [12, 25,  39,  54,  70,  88, 109, 132, 159, 190],
		12 => [ 7, 17,  25,  37,  49,  61,  73,  87, 101, 116],
		15 => [ 6, 13,  21,  29,  38,  47,  56,  66],
		18 => [ 5, 11,  17,  24,  30,  36,  44],
		21 => [ 4,  9,  15,  20,  26,  31,  37],
		24 => [ 4,  8,  13,  18,  23,  28],
		27 => [ 3,  7,  11,  16,  20,  24],
		30 => [ 3,  7,  10,  14,  18],
		33 => [ 3,  6,  10,  13],
		36 => [ 3,  6,   9],
		39 => [ 3],
	},
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

sub _feet2metres {
	my ($this, %args) = @_;

	local $Carp::CarpLevel = 1;	# Auto-strip one level of calls.

	if ($args{feet} and $args{metres}) {
		croak "Both feet and metres arguments supplied to Sport::Dive::Tables";
	} elsif ($args{feet}) {
		return $args{feet} * FEET2METRES;
	} elsif (not $args{metres}) {
		croak "Missing mandatory 'feet' or 'metres' parameter to Sport::Dive::Tables::dive";
	}
	return $args{metres};
}

# Clear all status, except table.  This is done by a recall of
# _init.
sub clear {
	$_[0]->_init(table => $_[0]->table);
}

# Simple accessor method.
sub table { return $_[0]->{table}; }

sub group { 
	my $this = shift;
	if ($this->{surface} <= MIN_SURFACE_TIME) {
		return $this->{group};
	} elsif ($this->{surface} >= MAX_SURFACE_TIME) {
		return "";
	}

	# Looks like we've been off-gassing for a while.  Let's
	# find what group we're in now.

	my @times = sort {$a <=> $b} keys %{$SURFACE{$this->{table}}{$this->{group}}};

	foreach my $time (@times) {
		if ($this->{surface} < $time) {
			return $SURFACE{$this->{table}}{$this->{group}}{$time};
		}
	}
	die("Incomplete table for $this->{surface} minutes surface interval in group $this->{group}");
}

# Residual nitrogen time.
sub rnt {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);

	# XXX - Depth should be calculated, since it may be between
	# table entries.
	my $depth = $args{metres};

	# Lookup group, returning 0 RNT if they're completely free
	# of nitrogen.

	my $group = $this->group or return 0;

	# Get the group index.  A is 0, B is 1, C is 2, ...
	my $group_idx = ord('A') - ord($group);

	# Now just lookup the RNT.
	# XXX - What do we do if they're off the table?
	return $RESIDUAL{$this->{table}}{$depth}[$group_idx];
}

# Returns total surface time.
sub surface {
	my ($this, %args) = @_;
	$args{minutes} or return $this->{surface};
	$this->{surface} += $args{minutes};
	return $this->{surface};
}

sub max_time {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);
	
	# Walk through table until we find our depth, then lookup max.
	foreach my $depth (@{$DEPTHS{$this->{table}}}) {
		return $LIMITS{$this->{table}}{$depth}[-1] if $depth >= $args{metres};
	}
	croak "Depth of $args{metres} is not on $this->{table} table";
}

sub dive {
	my ($this, %args) = @_;

	# Reset surface time.
	# XXX - Update group first.
	$this->{surface} = 0;

	$args{metres} = $this->_feet2metres(%args);

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
