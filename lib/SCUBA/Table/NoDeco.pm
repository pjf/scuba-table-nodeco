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

our %SURFACE = (
    SSI => {
        A => { 12*60+ 0 => "A" },
	B => { 12*60+ 0 => "A", 3*60+20 => "B" },
	C => { 12*60+ 0 => "A", 4*60+49 => "B", 1*60+39 => "C" },
	D => { 12*60+ 0 => "A", 5*60+48 => "B", 2*60+38 => "C", 1*60+ 9 => "D"},
	E => { 12*60+ 0 => "A", 6*60+34 => "B", 3*60+24 => "C", 1*60+57 => "D",
                  54+ 0 => "E" },
	F => { 12*60+ 0 => "A", 7*60+ 5 => "B", 3*60+57 => "C", 2*60+28 => "D",
	        1*60+29 => "E", 0*60+45 => "F" },
	# TODO, Finish for G-K.
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

# Which depths appear on our limit charts, in numerically ascending order.
our %LIMIT_DEPTHS = (
	SSI => [sort {$a <=> $b} keys %{$LIMITS{SSI}}],
);

# Same for residual depths.  For SSI there are less depths on the residual
# table, so we must interpret some repetitve dives as deeper than they
# really are.
our %RESIDUAL_DEPTHS = (
	SSI => [sort {$a <=> $b} keys %{$RESIDUAL{SSI}}],
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
	$this->{table}     = $args{table}   || "SSI"; # Tables to use.
	$this->{group}     = $args{group}   || "";    # Initial group.
	$this->{surface}   = $args{surface} || 0;     # Surface time.
	$this->{bent}      = "";                      # Are we bent/reason?

	$this->{dive_time} = 0; # Used for consequtive dives with less than...
	$this->{last_depth}= 0; # ... MIN_SURFACE_TIME between them.

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

# This converts the depth given into a 'standard depth' as what appears
# on the chart.  If we're performing a repetitive dive (ie, our group
# is non-empty) then we'll read from RESIDUAL_DEPTHS, otherwise for
# a fresh dive we'll read from LIMIT_DEPTHS.  This means we may treat
# some shallow repetitve dives as deeper than they really are.  (This
# errs on the side of safety).

sub _std_depth {
	my ($this, %args) = @_;
	die "Incorrect call to Sport::Dive::Tables::_std_depth, no metres arg." unless $args{metres};

	# Find the correct table to use.
	my @depths;
	if ($this->group) {
		@depths = @{$RESIDUAL_DEPTHS{$this->{table}}};
	} else {
		@depths = @{$LIMIT_DEPTHS{$this->{table}}};
	}

	foreach my $depth (@depths) {
		return $depth if $depth >= $args{metres};
	}
	local $Carp::CarpLevel = 1;	# Auto-strip one level of calls.
	croak "Supplied depth $args{metres} metres is not on $this->{table} charts.";
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

	my $depth = $this->_std_depth(metres => $args{metres});

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

# XXX - Handle RNT.
sub max_time {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);
	my $depth = $this->_std_depth(metres => $args{metres});

	my $max_time = $LIMITS{$this->{table}}{$depth}[-1] - 
	               $this->rnt(metres => $depth);

	$max_time or croak "Depth of $args{metres} is not on $this->{table} table";
	return $max_time;
}

sub dive {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);

	# Calculate group.  This is done by looping over the list
	# of depths until we find one equal to or greater than our
	# current dive depth.

	my $group = "A";
	my $depth = $this->_std_depth(metres => $args{metres});
	my $tbt;

	if ($this->surface > MIN_SURFACE_TIME) {
		$tbt = $args{minutes} + $this->rnt(metres => $depth);
	} else {
		$tbt = $this->{dive_time} + $args{minutes};
		$depth = $depth > $this->{last_depth} ? $depth : $this->{last_depth};
	}

	# Record dive information.

	$this->{surface}    = 0;
	$this->{last_depth} = $depth;
	$this->{dive_time}  = $tbt;

	foreach my $time (@{$LIMITS{$this->{table}}{$depth}}) {
		# Now walk through all our groups until
		# we find one with a time equal to or
		# greater than our current time.

		if ($time >= $tbt) {
			$this->{group} = $group;
			return $group;
		}
		$group++;
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
