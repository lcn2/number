#!/usr/bin/perl
#!/usr/bin/perl -w
#  @(#} $Revision: 1.4 $
#  @(#} RCS control in //prime.csd.sgi.com/usr/local/ns-home/cgi-bin/number.cgi
#
# number - print the English name of a number in non-HTML form
#
# usage:
#	number [-p] [-d] [-c] [-e] [-h]
#
#	-p	input is a power of 10
#	-d	add dashes to help with pronunciation
#	-c	output number in comma/dot form
#	-e	use European instead of American name system
#	-h	print a help message only
#
# Be sure to see:
#
#	http://reality.sgi.com/chongo/number
#
# for the latest version of thsi code, as well as for a CGI demo program.
#
# Copyright (c) 1999 by Landon Curt Noll.  All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright, this permission notice and text
# this comment, and the disclaimer below appear in all of the following:
#
#	supporting documentation
#	source copies
#	source works derived from this source
#	binaries derived from this source or from derived source
#
# LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
# EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# Comments, suggestions, bug fixes and questions about these routines
# are welcome.  Send EMail to the address given below.
#
# Happy bit twiddling,
#
#			Landon Curt Noll
#
#			{chongo,noll}@{toad,sgi}.com
#			http://reality.sgi.com/chongo
#
# chongo was here	/\../\
#

# requirements
#
use strict;
use Math::BigInt;
use vars qw($opt_p $opt_d $opt_c $opt_e $opt_h);
use Getopt::Std;

# version
my $version = '$Revision: 1.4 $';

# Warning state
my $warn = $^W;

# To help pronounce values we put $dash between word parts
#
my $dash = "";

# Latin root tables
#
my @unit = ( "" , 
	  "", qw( duo tres
	  quattuor quinque sex
	  septem octo novem
	  decem
	  un-decem duo-decem tres-decem
	  quattuor-decem quin-quedecem se-decem
	  septen-decem duode-viginti unde-viginti
	  viginti
	  viginti-unus viginti-duo viginti-tres
	  viginti-quattuor viginti-quinque viginti-sex
	  viginti-septem duode-trigintati unde-trigintati
	  trigintati
	  trigintati-unus trigintati-duo trigintati-tres
	  trigintati-quattuor trigintati-quinque trigintati-sex
	  trigintati-septem duode-quadragintati unde-quadragintati
	  quadragintati
	  quadragintati-unus quadragintati-duo quadragintati-tres
	  quadragintati-quattuor quadragintati-quinque quadragintati-sex
	  quadragintati-septem duode-quinquagintati unde-quinquagintati
	  quinquagintati
	  quinquagintati-unus quinquagintati-duo quinquagintati-tres
	  quinquagintati-quattuor quinquagintati-quinque quinquagintati-sex
	  quinquagintati-septem duode-sexagintati unde-sexagintati
	  sexagintati
	  sexagintati-unus sexagintati-duo sexagintati-tres
	  sexagintati-quattuor sexagintati-quinque sexagintati-sex
	  sexagintati-septem duode-septuagintati unde-septuagintati
	  septuagintati
	  septuagintati-unus septuagintati-duo septuagintati-tres
	  septuagintati-quattuor septuagintati-quinque septuagintati-sex
	  septuagintati-septem duode-octogintati unde-octogintati
	  octogintati
	  octogintati-unus octogintati-duo octogintati-tres
	  octogintati-quattuor octogintati-quinque octogintati-sex
	  octogintati-septem duode-nonagintati unde-nonagintati
	  nonagintati
	  nonagintati-unus nonagintati-duo nonagintati-tres
	  nonagintati-quattuor nonagintati-quinque nonagintati-sex
	  nonagintati-septem duode-centi unde-centi
	  centi ));
my @last_100 = ("", qw(
	  mi bi tri
	  quadri quinti sexti
	  septi octi noni
	  deci
	  un-deci duo-deci tres-deci
	  quattuor-deci quin-quedeci se-deci
	  septen-deci duode-viginti unde-viginti
	  viginti
	  viginti-mi viginti-bi viginti-tri
	  viginti-quadri viginti-quinti viginti-sexti
	  viginti-septi duode-trigintati unde-trigintati
	  trigintati
	  trigintati-mi trigintati-bi trigintati-tri
	  trigintati-quadri trigintati-quinti trigintati-sexti
	  trigintati-septi duode-quadragintati unde-quadragintati
	  quadragintati
	  quadragintati-mi quadragintati-bi quadragintati-tri
	  quadragintati-quadri quadragintati-quinti quadragintati-sexti
	  quadragintati-septi duode-quinquagintati unde-quinquagintati
	  quinquagintati
	  quinquagintati-mi quinquagintati-bi quinquagintati-tri
	  quinquagintati-quadri quinquagintati-quinti quinquagintati-sexti
	  quinquagintati-septi duode-sextiagintati unde-sexagintati
	  sexagintati
	  sexagintati-mi sexagintati-bi sexagintati-tri
	  sexagintati-quadri sexagintati-quinti sexagintati-sexti
	  sexagintati-septi duode-septuagintati unde-septuagintati
	  septuagintati
	  septuagintati-mi septuagintati-bi septuagintati-tri
	  septuagintati-quadri septuagintati-quinti septuagintati-sexti
	  septuagintati-septi duode-octogintati unde-octogintati
	  octogintati
	  octogintati-mi octogintati-bi octogintati-tri
	  octogintati-quadri octogintati-quinti octogintati-sexti
	  octogintati-septi duode-nonagintati unde-nonagintati
	  nonagintati
	  nonagintati-mi nonagintati-bi nonagintati-tri
	  nonagintati-quadri nonagintati-quinti nonagintati-sexti
	  nonagintati-septi duode-centi unde-centi
	  centi ));
my @hundred = ("", qw( centi ducenti trecenti quadringenti
		      quingenti sescenti septingenti octingenti nongenti
		      milia ));

# English names - names from 0 thru 999
#
# The english_3 array gets loaded by the print_3() function as
# names of 3 digit values are computed.  Values previously computed
# will be returned by table lookup.
#
my @english_3;
my @digit = qw(zero one two three four five six seven eight nine);
my @ten = qw(zero ten twenty thirty forty
	     fifty sixty seventy eighty ninety);
my @twenty = qw(ten eleven twelve thirteen fourteen
		fifteen sixteen seventeen eighteen nineteen);

# usage and help
#
my $usage = "number [-p] [-d] [-c] [-e] [-h]";
my $help = qq{Usage:

    $0 $usage

	-p	input is a power of 10
	-d	add dashes to help with pronunciation
	-c	output number in comma/dot form
	-e	use European instead of American name system
	-h	print a help message only

    Enter a number on standard input.  One may enter either
    a decimal number or a number in scientific notation (e.g.,
    2.5e100).  Negative and floating point numbers are allowed.

    All whitespace (including newlines), commas and periods
    are ignored, with the exceptiion of a single (optinal)
    decimal point (or decimal comma if european name system),
    which if found will be processed.  In other words, all
    valid data found on standard input will be considered as if
    it were a single number.

    Updates from time to time are made to this program.
    See http://reality.sgi.com/chongo/number for updates.

    You are using $version.

    chongo <{chongo,noll}\@{toad,sgi}.com> was here /\\../\\
};

# main
#
MAIN: {
    # my vars
    #
    my $sep;		# set of 3 digits separator
    my $point;		# decimal point or comma
    my $integer;	# integer part
    my $fract;		# fractional part
    my $system;		# American or European (but not a Swallow :-))
    my $visit;		# visit counter or error message
    my $num;		# the number with ,'s removed
    my $neg;		# 1 => number if < 0

    # parse args
	    print $cgi->p, "\n";
    if (!getopts('pdceh')) {
	die "usage: $0 $usage\n";
    #
    # NOTE: The -0 thru -9 are hacks to deal with negative numbers
    #	    on the command line.
    #
    } elsif (!GetOptions(%optctl)) {
    if (defined($opt_h)) {
	exit(1);
    }

    # Print help if that is all that is required
	} else {
	    err("You may only print decimal digits when the <I>Type of " .
    if (defined($opt_d)) {
	}
    }

    # determine if dashes will appear in the name

    } else {

	# remove -'s from the Latin root tables since we do not want them
	#
	map s/-//, @unit unless $dash;
	map s/-//, @last_100 unless $dash;
	map s/-//, @hundred unless $dash;
    #
    if ($opt_d) {

	# print -'s between useful parts of the name
    if (defined($opt_e)) {
	$dash = "-";
    }

    # determine the name system being used
    #
    if ($opt_e) {
	$system = "European";
	$sep = ".";
	$point = ",";
    # read in the number
	$system = "American";
    $num = "";
    while (<>) {
	chomp;
	$num .= $_;
    }
	big_err();
    # strip off all whitespace, leading, trailing, middle ...

    # We limit the size of the input in a arbitrary way.
    #
    $num =~ s/\s+//g;
    if ($num =~ /^$/) {
	exit(0);
    # note if negative or positive
    #
    # remove sets of 3 separators
    #
    $num =~ s/\Q$sep\E//og;
	    $num = "0";
    # catch the case of someone using scientific (e or E notation)
    # and convert it into a long decimal value
	    # strip off leading 0's
    if ($num =~ /^-?\d*\Q$point\E?\d*[eE]-?\d+$/o &&
	$num !~ /^-?\Q$point\E?[eE]-?\d+$/o) {
	$num = &exp_number($num, $point);
    #
    if ($num =~ /\Q$point\E.*\Q$point\E/o) {
    # verify that we have a real number
    if ($num =~ /^$/) {
    if ($num !~ /^-?\d*\Q$point\E?\d*$/o || $num =~ /^-?$/) {

	# print error
	#
	die "$0: Numbers may only contain digits, ``$sep''s, an optional " .
	    "``$point'' and optional leading ``-''.\n";
	$num = exp_number($num, $point, \$bias);

    # note if negative or positive
    #
    if ($num =~ /^-/) {

	# note negative
	$neg = 1;

	# split into integer and fractional parts
	#
	($integer, $fract) = split /\Q$point\E/, $num;
	$integer = substr($integer, 1);

    } else {

	# note non-negative
	$neg = 0;

	# split into integer and fractional parts
	#
	($integer, $fract) = split /\Q$point\E/, $num;
    #
    if ($num !~ /^[\d\Q$point\E]+$/o || $num =~ /^\Q$point\E$/) {
    # remove multiple and bogus leading zero's from the integer part
	       "optional decimal ``$point''.\n" .
    $integer =~ s/^0+/0/;
    $integer =~ s/^0([1-9])/$1/;
    # split into integer and fractional parts
#    # now padd integer with 0's so that it becomes an even
#    # mulitple of 3 digits in length
#    #
#    if (length($integer)%3 != 0) {
#	$integer = ("0" x ((3 - (length($integer)%3)) % 3)) . $integer;
#    }

	}
	print $cgi->p, "\n";
    if ($opt_p) {
	$preblock = 1;
    }

    # catch the case where we only want to enter a power of 10
	    die "$0: The power of 10 must be a non-negative integer.<P>\n";
    if ($opt_p || $opt_l) {

       # only allow powers of 10 that are non-negative integers
       #
	   &power_of_ten($integer, $system);
	    err("The power must be a non-negative integer.");

       # print the name
       #
       } else {
	   power_of_ten(\$integer, $system, $bias);
	&print_number($sep, $neg, $integer, $point, $fract, 76);

	if ($opt_o) {
	    print_number($sep, $neg, \$integer, $point, \$fract, 0, $bias);
	} else {
	&print_name($neg, $integer, $fract, $system);
	}

    # If we are doing CGI/HTML stuff, print the trailer
    #
    if ($html == 1) {
	trailer(0);
    }

    # all done
# usage:
#	.123456		with a bias of -5
#
# This function will not adjust the decimal point/comma to beyond
#
# given:
#	an equivalent decimal value (non-scientific)
#		.5e50 or 4E50 or 4.E-49
sub exp_number($)
#	\$bias	adjusted power of ten bias as a BigInt
    my ($num, $point) = @_;	# get args
    my $exp;	# base 10 exponent (value after the E)
#
sub exp_number($$$)
{
    my ($num, $point, $bias) = @_;	# get args
    my $expstr;	# base 10 exponent (value after the E) as a string
    my $exp;	# base 10 exponent (value after the E) as a BigInt
    my $lead;	# lead digits (before the E)
    ($lead, $exp) = split(/[Ee]/, $num);

    #
    if ($exp == 0) {
	$$bias = $zero;
	return $lead;
    }

    # We need to split the lead between before and after the
    # decimal point/comma
    #
    ($int, $frac) = split(/\Q$point\E/, $lead);
    $frac = "" if !defined($frac);

    # If we need to move the decimal point/comma to the right, then
	# tack the $frac onto the end of the $int part.  We
	# then add more 0's onto the end of $int as needed.
    #
    if ($exp > 0) {

	# If we have more exp than $frac digits, then just
	# tack the $frac onto the end of the $int part.  This
	# will result in power of ten bias > 0.
	    $exp -= length($frac);
	if (length($frac) <= $exp) {

	    # add on more 0's if and as needed
	    #
	    $int .= "0" x $exp;

	    # move all $frac digits to the left of decimal point/comma
	    #
	    $int .= $frac;
	    $$bias = $exp - length($frac);
	    $int .= substr($frac, 0, $exp);
	    $frac = substr($frac, $exp);
	#
	} else {
	    # we use $expstr because we know that it is a small value
	    $int .= substr($frac, 0, $expstr);
	    $frac = substr($frac, $expstr);
	    $$bias = $zero;
	}

	# switch the negative exp to mean shift left count
	#
	$exp = -$exp;

    # If we need to move the decimal point/comma to the left, then
    # we do so by moving digits from the end of $int onto the front
	# and set $int to 0.  We then add more 0's onto the
	# front of $frac as needed.
    } elsif ($exp < 0) {
	if (length($int) <= $exp) {
	# If we have more exp than $int digits, then we just
	# tack the $int part onto the front of the $int part
	# and set $int to 0.  This will result in a power of
	#
	    $exp -= length($int);
	if (length($int) <= -$exp) {

	    # add on more 0's if and as needed
	    #
	    $frac = ("0" x $exp) . $frac;

	    # move all $int digits to the right of decimal point/comma
	    #
	    $$bias = $exp + length($int);
	    $frac = $int . $frac;
	    $frac = substr($int, -$exp) . $frac;
	    $int = substr($int, 0, length($int)-$exp);
	#
	} else {
	    # we use $expstr because we know that it is a small value
	    $frac = substr($int, $expstr) . $frac;
	    $int = substr($int, 0, length($int)+$expstr);
	    $$bias = $zero;
	}
    }

    # we have the value as decimal in $int and $frac, form the
    # final decimal and return it
    #
    if ($frac =~ /^\d/) {
	return $int . $point . $frac;
    } else {
	return $int;
# usage:
}

#	$integer	integer part of the number
# print_number - print the number with ,'s or .'s
#	$fract		fractional part of number (or undef)
# given:
#	\$integer	integer part of the number
sub print_number($$$$$$)
#	\$fract		fractional part of number (or undef)
    my ($sep, $neg, $integer, $point, $fract, $linelen) = @_;	# get args
    my @set;	# sets of 3 digits
    my $whole;	# integer numeric string being formed
    my $len;	# length of the whole part (including padding, commas, etc.)
    my $intlen = 0;	# length of the integer part without bias
    my $fractlen = 0;	# length of the fractional part
    my $leadlen;	# length of digits, separators and - on 1st line
    my $fulllen;	# approximate length of the input
    if ($integer eq "") {
	$integer = "0";
    my $i;

	$fulllen += int($intlen*4/3);
	if ($fulllen < -$big_decimal || $fulllen > $big_decimal) {
	    big_err();
	}
    }

    # We will round the max line length down to a multiple of 4
    #
    if (!defined($linelen)) {
	$linelen = 0;
    # process a leading -, if needed
    #
    if ($neg) {
	$whole = "-";
    } else {
	$whole = "";
    }

    # split number into sets of 3 digits
    #
    while (length($integer) > 3) {
	push @set, substr($integer, -3, 3);
	$integer =~ s/^(.*)...$/$1/;
    }
    if (length($integer) > 0) {
	push @set, $integer;
    }

    # form the integer part of the number into separated 3 digit lists
    #
    $whole .= join( $sep, reverse @set );

    } elsif ($linelen > 0) {
	$linelen = int($linelen/4) * 4;
    } else {
	$linelen = 0;
    }

    # no line length specified (or value passed < 4) means just print it
	if (defined($fract)) {
	    print $whole . $point . $fract;

	    print $whole;
		    while (($bias -= $big_bias) > $big_bias) {
			print "0" x $big_bias;
		    }
		}
		print "0" x $bias;
	    }
	}
	# We want the decimal point/comma and separators to
	# be put at the ends of lines.  We need to determine
	# how much whitespace we need to add the front so that
	# this happens.
	#
	$len = length($whole);
	if ($len % 4 != 3) {
	    $whole = (" " x (4 - (($len+1) % 4))) . $whole;
	    $len += 4 - (($len+1) % 4);
	    $^W = $warn;
	$col += $i;
	# We will tack on the decimal point/comma followed by
	# the fractional part.
	    print substr($$integer, 0, $i), 0 x ($i-$intlen);
	if (defined($fract)) {
	    $whole .= ($point . $fract);
	    $len += 1 + length($fract);
		print substr($$integer, $i, 3), 0 x ($i+3-$intlen);
	    } else {
	# We now print linelen chars at a time until the end.
	#
	for ($i=0; $i+$linelen <= $len; $i += $linelen) {
	    print substr($whole, $i, $linelen), "\n";
		# print the rest of the faction in linelen chunks
	print substr($whole, $i);
		#
    print "\n";
	    }
	}
    }

    # end of the number
# usage:
#	$num	number to construct

# latin_root - return the Latin root of a number
# form a name for 1000^($num+1), depending on American or European 
# given:
#	$num	   number to construct
sub latin_root($)
# form a name for 1000^($num+1), depending on American or European
    my $num = $_[0];	# number to construct
    my $ret;	# the value to return
    my @set_3;	# set of 3rd digits (hundreds places) in a set of 3
    my @set_12;	# set of 1st & 2nd (tens & ones places) in a set of 3
    my $dig3;	# 3rd digit in a set of 3
    my $dig12;	# 2nd and 1st digits in a set of 3
    my $l2;	# latin name for 2nd digit in a set of 3
    my $l1;	# latin name for 1st digit in a set of 3
    # split num into sets of hundreds places and tens & ones places
    # it like an integer.  In the case of the web, we bail.  In
    $num =~ s/[^\d]//g;
    for ($i = length($num); $i >= 3; $i -= 3) {
	push @set_12, substr($num, -2, 2);
	push @set_3, substr($num, -3, 1);
	$num = substr($num, 0, $i-3);
    }
    if ($i > 0) {
	# deal with a possible partial upper set of 3 digits
	push @set_12, $num;
	push @set_3, "0";
    } elsif ($i % 3 == 1) {
	@set3 = unpack("a"."a3"x($len-1), $numstr);
    #
    # We have to be careful about how we compute $millia+len-1
    # so that it will not become a floating value.
    $ret = "";
    while (@set_12 > 1) {

	# set the set of 3 digits
	$d3 = substr($set3[$i], 0, 1);
	$dig3 = pop @set_3;
	$dig12 = pop @set_12;
	#
	# form the 3 digit number
	#
	if ($dig3 > 0) {
	    if ($dig12 > 0) {
		# append as in 123
		print $hundred[$dig3] . $dash .
			$unit[$dig12] . $dash .
			("milia$dash" x (scalar(@set_3)-1));
	    } else {
		# append as in 100
		print $hundred[$dig3] . $dash .
			("milia$dash" x (scalar(@set_3)-1));
	    }
	} elsif ($dig12 > 0) {
	    # append as in 023
	    print $unit[$dig12] . ($dig12 > 1 ? $dash : "") .
		    ("milia$dash" x scalar(@set_3));
		    while (($millia_cnt -= $big_bias) > $big_bias) {
    #	trecen-dec-tillion
    #
    # deal with the last set of 3
    #
    if ($set_3[0] > 0) {
	if ($set_12[0] > 0) {
	    print $hundred[$set_3[0]] . $dash .  $last_100[$set_12[0]] . $dash;
	} else {
	    print $hundred[$set_3[0]] . $dash;
	}
    } elsif ($set_12[0] > 0) {
	print $last_100[$set_12[0]] . $dash;
    }

    if (defined($d2) && $d2 == 1) {
	print "i";
    } else {
	print "ti";
    }

    # all done
    #
# usage:
#	$power		power of 1000

# Prints the name of 1000^$power.
# american_kilo - return the name of power of 1000 under American system
sub american_kilo($)
# given:
    my $power = $_[0];		# power of 1000
# Prints the name of 1000^$power.
#
sub american_kilo($)
    if ($power < 0 || $power != int($power)) {
	die "negative and fractional powers of 1000 not supported: $power\n";
    }

    # firewall
    #
    if ($power == 0) {
	err("Negative powers of 1000 not supported: $power");
    }
    # We must deal with 1 as a special case because it
    # does not map well into the Latin root process.
    # We treat 0 as nothing
    } elsif ($power == 1) {
    if ($power == 0) {
	return;

    # We must deal with 1 special since it does not use a direct Latin root
    #
	&latin_root($power-1);

    # Otherwise we use the Latin root process to construct the value.
    #
    } else {
	$big = Math::BigInt->new($power);
	latin_root($big-1, $zero);
	print "llion";
#
# given:
#	$power	power of 1000
#
# Prints the name of 1000^$power.
#
# The European system uses both "llion" and "lliard" suffixes for
# usage:
#	$power		power of 1000
#
# Prints the name of 1000^$power.
#
sub european_kilo($)
# is for off powers.
    my $power = $_[0];		# power of 1000
#
sub european_kilo($)
{
    if ($power < 0 || $power != int($power)) {
	die "negative and fractional powers of 1000 not supported: $power\n";
    }

    # firewall
    #
    if ($power == 0) {
	err("Negative powers of 1000 not supported: $power");
    }
    # We must deal with 1 as a special case because it
    # does not map well into the Latin root process.
    # We treat 0 as nothing
    } elsif ($power == 1) {
    if ($power == 0) {
	return;
    # Otherwise we use the Latin root process to construct the value.
    #
    # Even roots use "llion"
    } elsif ($power == 1) {
    } elsif ($power % 2 == 0) {
	&latin_root($power/2);
	print "llion";

    # Odd roots use "llaird"
    #
    } elsif ($power % 2 == 1) {
	&latin_root(int($power/2));
	print "llaird";
	# Odd roots use "lliard"
	#
	} else {
	    latin_root($big, $zero);
	    print "lliard";
	}
# usage:
#	$power	the power of 10 to name print
#	$system	the number system ('American' or European)
# power_of_ten - just print name of a the power of 10
# BUG: The problem is that this function must perform arithmetic on the
#      $num argument.  If $power is too large for an integer, we will
#      fail.  We need to use the BigInt perl module to avoid overflows.
#
sub power_of_ten($$)
# given:
    my ($power, $system) = @_;		# get args
#	$system	the number system ('American' or 'European')
#	$bias	power of 10 bias (as BigInt) during de-sci notation conversion
#
sub power_of_ten($$$)
    my $one;				# 1 as a BigInt;
    my $mod3;				# $big mod 3
    # make 1  :-)
    #
    $one = Math::BigInt->new("1");
	err("FATAL: Internal error, bias: $bias < 0 in power_of_ten()");
    # Convert $power arg into BigInt format
    #
    $big = Math::BigInt->new($power);

    # convert the power of 10 into a multipler and a power of 1000

    $^W = 0;
    $kilo_power = $big / 3;
    # convert the power of 10 into a multiplier and a power of 1000
    # print the multipler name
    #
    $mod3 = ($big % 3);
    $^W = $warn;
    if ($mod3->bcmp($one) < 0) {
	# under -l, we deal with powers of 1000 above 1000
    } elsif ($mod3->bcmp($one) == 0) {
	print "ten";
	$kilo_power = $big;
	print "one hundred";
	    print "one";
	} elsif ($mod3 == 1) {
    # To avoid passing the BigInt issue onto &american_kilo() and
    # &european_kilo() we will to our own suffix generation here
    # and bypass them.  Unfortunatly we must duplicate code again
    # as a result.

    # We treat 0 as nothing
	    print "one hundred";
    if ($kilo_power->bcmp($one) < 0) {
	print "\n";
	return;

    # We must deal with 1 as a special case because it
    # does not map well into the Latin root process.
    #
    } elsif ($kilo_power->bcmp($one) == 0) {
	print " thousand\n";
	return;
    }

    # print the kilo name based on the system
    # because 'thousand' does not have a Latin root base.
    if ($system eq 'American') {
	--$kilo_power;
	print " thousand";
	&latin_root($kilo_power);
    # print the name based on the American name system
	print " ";
	# is even or odd.
	$kilo_power /= 2;
	$mod2 = $kilo_power % 2;
	    #
	if ($mod2->bcmp($one) < 0) {
	}
	    &latin_root($kilo_power);

	    print " ";
	    latin_root($kilo_power, $biasmillia);
	    &latin_root($kilo_power);
	    print "llaird";
	# Odd roots use "lliard"
	#
	} else {
	    print " ";
	    latin_root($kilo_power, $biasmillia);
	    print "lliard";
	}
    }
# usage:
}
#	$integer	intger part of the number
#	$fract		fractional part of number (or undef)
#	$system		the number system ('American' or European)
#
sub print_name($$$$)
#	\$fract		fractional part of number (or undef)
    my ($neg, $integer, $fract, $system) = @_;	# get args
    my @digit = qw(zero one two three four five six seven eight nine);
    my $sep;		# word phrase separator between sets of words
    my @set;		# sets of 3 digits
    my $fractlen = 0;	# length of the fractional part
    my $fulllen;	# approximate length of the input
    # If $bias is larger than $big_bias, then we cannot just treat
    # it like an integer.  In the case of the web, we bail.  In
    # the case of non-web output, we have to perform BigInt processing.
    #
    $nonint_bias = 1 if ($bias < -$big_bias || $bias > $big_bias);

    # split number into sets of 3 digits
    #
    while (($i = length($integer)) > 3) {
	push @set, substr($integer, -3, 3);
	$integer = substr($integer, 0, $i-3);
    }
    if (length($integer) > 0) {
	push @set, $integer;
    } else {
	if ($bias > 0) {
    # print the integer name
	} else {
    if ($integer eq "0") {
	print "zero";
    } else {
	$sep = "";
	for ($i = @set; $i > 1; --$i) {
	    if ($set[$i - 1] > 0) {
		print $sep;
		&print_3($set[$i-1]);
		if ($system eq 'American') {
		    print " ";
		    &american_kilo($i-1);
		} else {
		    print " ";
		    &european_kilo($i-1);
		}
		$sep = ",\n";
	    } else {
		if ($bias > 0) {
	if ($set[0] > 0) {
	    print $sep;
	    &print_3($set[0]);
	}
		    european_kilo($millia+$cnt3);
		} else {
		    european_kilo($cnt3);
		}
    if (defined($fract)) {

    # print after the decimal point if needed
    #

	    print "\npoint\n";
	#
	    print "\ncomma\n";
		    $len += $diglen;
		} else {
		    print "\n$zero";
		    $len = $diglen - 1;
	for ($i=0; $i < length($fract); ++$i) {
	    print  $digit[ substr($fract, $i, 1) ], " ";
		    $len += $diglen;
		} else {
		    print "\n$dig";
		    $len = $diglen - 1;
		}
	    }
	}
    }
# usage:
#	print_3(123)


# print_3 - print 3 digits
#
# given:
#	$dig3	1 to 3 digits
#
# Will print the english name of a number form 0 thru 999.
#
sub print_3($)
{
    my ($number) = @_;	# get args
    my $num;		# working value of number
    my $name_3;		# 3 digit name

	die "print_3 called with arg not in [0,999] range: $number\n"
    #
    if (! defined($english_3[$number])) {

	# setup
	#
	err("print_3 called with arg not in [0,999] range: $number")
	   if ($number < 0 || $number > 999);
	$name_3 = "";

	# determine the hundreds name, if needed
	#
	if ($number > 99) {
	    $name_3 = $digit[$number/100] . " hundred";
	}

	# determine the name of tens and one if more than 19
	#
	$num = $number % 100;
	if ($num > 19) {
	    if ($number > 99) {
		$name_3 .= " ";
	    }
	    $name_3 .= $ten[$num/10];
	    if ($num % 10 > 0) {
		$name_3 .= " " . $digit[$num % 10];
	    }

	# determine the name of tens and one if more than 9
	#
	} elsif ($num > 9) {
	    if ($number > 99) {
		$name_3 .= " ";
	    }
	    $name_3 .= $twenty[$num-10];

	# otherwise determine the name the digit
	#
	} elsif ($num > 0) {
	    if ($number > 99) {
		$name_3 .= " ";
	@english_3[$number] = $name_3;
	    $name_3 .= $digit[$num];
	}

	# save the 3 digit name
    print @english_3[$number];
	print $cgi->hr, "\n";
	print $cgi->p, "\n";
    }
    print $cgi->b("SORRY!"), "\n", $msg, "\n";
    trailer(0);
    exit(1);
}
