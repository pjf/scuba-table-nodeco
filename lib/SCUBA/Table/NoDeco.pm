package SCUBA::Table::NoDeco;

use strict;
use warnings;
use Carp;

our $VERSION = "0.01";

=head1 NAME

SCUBA::Table::NoDeco - Calculate no-decompression dive times.

=head1 SYNOPSIS

  use SCUBA::Table::NoDeco;

  my $table = SCUBA::Table::NoDeco->new();

  $table->dive(metres => 15, minutes => 30);

  print $table->group,"\n";	# Prints "E"

  $table->surface(minutes => 60);

  print $table->group,"\n";	# Prints "D"

  print $table->max_time(metres => 30),"\n";	# Prints 6

=head1 WARNING AND DISCLAIMER

Do B<NOT> use this module as your sole source of no-decompression dive
times.  This module is intended for use only as a guide to assist in
planning your dives.  B<ALWAYS> calculate and verify your dive times
by hand once you have planned your dives.  If you have a dive
computer, follow its instructions for use.

SCUBA diving involves serious risks of injury or death, and should
only be performed by individuals in good health and with the appropriate
skills and training.  Even when tables are used with proper safety
procedures, decompression sickness may still occur.

The author provides ABSOLUTELY NO WARRANTY on this module, without
even the implied warranty of merchantability or fitness for a particular
purpose.  Use entirely at your own risk.

=head1 DESCRIPTION

This module provides the ability to perform useful calculations
using dive-tables, including calculating dive groups and maximum
no-decompression times for repetitive dives.  A selection of tables
are available.  The module assumes that the diver is using air as
their breathing gas.

=head1 METHODS

The following methods are provided.

=cut

# There's really 0.3048 feet in a metre, but all the dive tables seem
# to assume a flat 1 ft = 30 cm.  As such, we use the same constant here,
# otherwise we end up with incorrect results.

use constant FEET2METRES => 0.3;

# Less than 10 minutes surface is considered part of the same dive.
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
	G => { 12*60+ 0 => "A", 7*60+35 => "B", 4*60+25 => "C", 2*60+58 => "D",
	        1*60+50 => "E", 1*60+15 => "F", 0*60+40 => "G" },
	H => { 12*60+ 0 => "A", 7*60+59 => "B", 4*60+49 => "C", 3*60+20 => "D",
	        2*60+23 => "E", 1*60+41 => "F", 1*60+06 => "G", 0*60+36 => "H"},
	I => { 12*60+ 0 => "A", 8*60+21 => "B", 5*60+12 => "C", 3*60+43 => "D",
	        2*60+44 => "E", 2*60+02 => "F", 1*60+29 => "G", 0*60+59 => "H",
		0*60+33 => "I" },
	J => { 12*60+ 0 => "A", 8*60+50 => "B", 5*60+40 => "C", 4*60+02 => "D",
	        3*60+04 => "E", 2*60+20 => "F", 1*60+47 => "G", 1*60+19 => "H",
		0*60+54 => "I", 0*60+31 => "J" },
	K => { 12*60+ 0 => "A", 8*60+58 => "B", 5*60+48 => "C", 4*60+19 => "D",
	        3*60+21 => "E", 2*60+38 => "F", 2*60+38 => "G", 1*60+35 => "H",
		1*60+11 => "I", 0*60+49 => "J", 0*60+28 => "K" },
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

=head2 new

    my $stn = SCUBA::Table::NoDeco->new(table => "SSI");

This class method returns a SCUBA::Table::NoDeco object.  It takes
an optional I<table> argument, specifying which dive table should be
used.

If no dive table is supplied then the module will use the default
SSI table.  This default may change in future releases, so you should
not rely upon this default.

SSI tables are the only ones supported in the present release.

=cut

sub new {
	my $class = shift;
	my $this = {};
	bless($this,$class);
	$this->_init(@_);
	return $this;
}

=head2 list_tables

  my @tables = SCUBA::Table::NoDeco->list_tables();

This method returns a list of tables that can be selected when creating
a new SCUBA::Table::NoDeco object.

=cut

sub list_tables {
	return keys %RESIDUAL;
}

=head2 max_depth

  my $max_depth_ft = $stn->max_depth(units => "feet");
  my $max_depth_mt = $stn->max_depth(units => "metres");

This method provides the maximum depth provided by the tables currently
in use.  It I<does not> supply the maximum safe depth.  The units argument
is mandatory.

=cut

sub max_depth {
	my ($this, %args) = @_;
	if ($args{units} eq "metres") {
		return $RESIDUAL_DEPTHS{$this->table}[-1] 
	} elsif ($args{units} eq "feet") {
		return $RESIDUAL_DEPTHS{$this->table}[-1] / FEET2METRES;
	} else {
		croak "max_depth requires units parameter of 'metres' or 'feet'";
	}
}

sub _init {
	my ($this, %args) = @_;
	$this->{table}     = $args{table}   || "SSI"; # Tables to use.
	$this->{group}     = $args{group}   || "";    # Initial group.
	$this->{surface}   = $args{surface} || 0;     # Surface time.

	$this->{dive_time} = 0; # Used for consequtive dives with less than...
	$this->{last_depth}= 0; # ... MIN_SURFACE_TIME between them.

	croak "Non-existant table $args{table} supplied" unless exists $RESIDUAL{$this->{table}};

	return $this;
}

sub _feet2metres {
	my ($this, %args) = @_;

	local $Carp::CarpLevel = 1;	# Auto-strip one level of calls.

	if ($args{feet} and $args{metres}) {
		croak "Both feet and metres arguments supplied to SCUBA::Table::NoDeco";
	} elsif ($args{feet}) {
		croak "Positive depth must be supplied" if $args{feet} <= 0;
		return $args{feet} * FEET2METRES;
	} elsif (not $args{metres}) {
		croak "Missing mandatory 'feet' or 'metres' parameter to SCUBA::Table::NoDeco::dive";
	}
	croak "Positive depth must be supplied" if $args{metres} <= 0;
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
	die "Incorrect call to SCUBA::Table::NoDeco::_std_depth, no metres arg." unless $args{metres};

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

=head2 clear

   $stn->clear();

This method resets the object to its pristine state.  The table used for
dive calculations is retained.

=cut

# Clear all status, except table.  This is done by clearing the underlying
# hash entirely and recalling _init.  There is almost certainly a faster
# and more effective way to remove all the keys without re-creating the
# reference.

sub clear {
	my $table = $_[0]->table;
	foreach my $key (keys %{$_[0]}) {
		delete $_[0]->{$key};
	}
	$_[0]->_init(table => $table);
}

=head2 table

  print "You are using the ",$stn->table," tables\n";

This method simply returns the name of the dive table being used by
the C<SCUBA::Table::NoDeco> object.

=cut

sub table { return $_[0]->{table}; }

=head2 dive

  my $group = $stn->dive(feet   => 60, minutes => 30);
  my $group = $stn->dive(metres => 18, minutes => 30);

This method determines and sets the diver's group for the dive information
provided.  If the dive 'falls off' the tables, then an exception is
returned.  This method takes into account the diver's current group,
surface interval, and residual nitrogen time.

If the diver does not have a surface interval of at least 10 minutes,
this will consider the dive to be a continuation of the previous
dive.  The dive times will be added, and the maximum depth of both
dives will be used to calculate the diver's group.

=cut

sub dive {
	my ($this, %args) = @_;

	$args{minutes} ||= 0;

	croak "Positive minutes argument required for SCUBA::Table::NoDeco::dive" if $args{minutes} <= 0;

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

	croak "SCUBA::Table::NoDeco::dive called with a depth or time not listed on the $this->{table} table";
}

=head2 group

  print "You are a ",$stn->group," diver\n";

The group method returns the current letter designation representing
the amount of residual nitrogen present in the diver.  The letter
designation is always upper-case.  A diver with no residual nitrogen
has no group, represented by the empty string.

=cut

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


=head2 surface

   $stn->surface(minutes => 60);	# Spend an hour on surface.
   print "Total surface time ",$stn->surface," minutes\n";

This method returns the total time of the current surface interval.
If the optional C<minutes> argument is provided, this is added to the
diver's current surface interval before returning the total minutes
elapsed.

=cut

# Returns total surface time.
sub surface {
	my ($this, %args) = @_;
	$args{minutes} or return $this->{surface};
	$this->{surface} += $args{minutes};
	return $this->{surface};
}

=head2 max_time

  print "Your maximum time at 18 metres is ",$stn->max_time(metres => 18),"\n";
  print "Your maximum time at 60 feet is   ",$stn->max_time(feet   => 60),"\n";

This calculates the maximum no-decompression time for a dive to the
specified depth.  The diver's current group is taken into account.

=cut

sub max_time {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);
	my $depth = $this->_std_depth(metres => $args{metres});

	my $max_time = $LIMITS{$this->{table}}{$depth}[-1] - 
	               $this->rnt(metres => $depth);

	$max_time or croak "Depth of $args{metres} is not on $this->{table} table";
	return $max_time;
}

=head2 rnt

   my $rnt  = $stn->rnt(metres => 12);
   my $rnt2 = $stn->rnt(feet   => 40);

This method returns the I<residual nitrogen time> for a diver, in minutes.
The depth argument (in either metres or feet) is mandatory.

=cut

sub rnt {
	my ($this, %args) = @_;

	$args{metres} = $this->_feet2metres(%args);

	my $depth = $this->_std_depth(metres => $args{metres});

	# Lookup group, returning 0 RNT if they're completely free
	# of nitrogen.

	my $group = $this->group or return 0;

	# Get the group index.  A is 0, B is 1, C is 2, ...
	my $group_idx = ord($group) - ord('A');

	# Now just lookup the RNT.
	return $RESIDUAL{$this->{table}}{$depth}[$group_idx];
}

1;
__END__

=head1 BUGS

Almost certainly.  If you find one, please report it to pjf@cpan.org.

=head1 AUTHOR

Paul Fenwick, E<lt>pjf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Paul Fenwick.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
