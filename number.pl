#!/usr/bin/perl -w
#!/usr/bin/perl
#  @(#} $Revision: 1.17 $
#  @(#} RCS control in //prime.csd.sgi.com/usr/local/ns-home/cgi-bin/number.cgi
#
# number - print the English name of a number in non-HTML form
#
# usage:
#	number [-p] [-L] [-d] [-m] [-c] [-l] [-e] [-h] [number]
#
#	-p	input is a power of 10
#	-L	input is a Latin power of 1000
#	-d	add dashes to help with pronunciation
#	-m	output name in a more compact exponentation form
#	-c	output number in comma/dot form
#	-l	output number on a single line
#	-e	use European instead of American name system
#	-h	print a help message only
#
# If number is omitted, then it is read from standard input.
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
# With many thanks for Latin suggestions from:
#
#			Jeff Drummond
#			jjd at sgi.com
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
use vars qw($opt_p $opt_L $opt_d $opt_m $opt_c $opt_l $opt_e $opt_h);
use Getopt::Std;
# CGI requirements
use CGI qw(:standard);

# version
my $version = '$Revision: 1.17 $';

# Warning state
my $warn = $^W;

# To help pronounce values we put $dash between word parts
#
my $dash = "";

# Latin root tables
#
my @l_unit = ( "" , qw( un do tre quattuor quin sex septen octo novem ));
my @l_ten = ("", qw( dec vigin trigin quadragin quinquagin
		     sexagin septuagin octogin nonagin ));
my @l_hundred = ("", qw( cen ducen trecen quadringen quingen
		         sescen septingen octingen nongen ));
my @l_special = ("", qw( mi bi tri quadri quinti sexti septi octi noni ));

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

# CGI / HTML variables
#
my $html = 0;		# 1 => be are being invoked as a CGI script

# usage and help
#
my $usage = "number [-p] [-L] [-d] [-m] [-c] [-l] [-e] [-h] [number]";
my $help = qq{Usage:

    $0 $usage

	-p	input is a power of 10
	-L	input is a Latin power of 1000
	-d	add dashes to help with pronunciation
	-m	output name in a more compact exponentation form
	-c	output number in comma/dot form
	-l	output number on a single line
	-e	use European instead of American name system
	-h	print a help message only

    If number is not given on the command line it is read from standard
    input.

    All whitespace (including newlines), commas and periods
    are ignored, with the exceptiion of a single (optinal)
    decimal point (or decimal comma if european name system),
    which if found will be processed.  In the case of reading from
    standard input, all valid data found on standard input will be
    considered as if it were a single number.

    A number may be either a in decimal or in scientific notation (e.g.,
    2.5e100).  Negative and floating point numbers are allowed.

    Updates from time to time are made to this program.
    See http://reality.sgi.com/chongo/number for updates.

    You are using $version.

    chongo <{chongo,noll}\@{toad,sgi}.com> was here /\\../\\
};

# main
#
MAIN:
{
    # my vars
    #
    my $sep;		# set of 3 digits separator
    my $point;		# decimal point or comma
    my $integer;	# integer part
    my $fract;		# fractional part
    my $system;		# American or European (but not a Swallow :-))
    my $visit;		# visit counter or error message
    my $num;		# input value
    my $neg;		# 1 => number if < 0
    my $q;		# CGI object, if invoked as a CGI script

    # setup
    #
    select(STDOUT);
    $| = 1;

    # determine if we are CGI based
    #
    if ($0 =~ /\.cgi$/) {

	# we are a CGI script, web restictions apply
	$html = 1;

	# CGI setup
	#
	$q = new CGI;
	$q->use_named_parameters(1);
	    print "Content-type: text/plain\n\n";
	    print "Your browser sent bad or too much data!\n";
	    print "Error: ", cgi_error(), "\n";
	$num = &cgi_form($q);
	}
	if (! defined $num) {
	    print $cgi->p, "\n";
    } elsif (!getopts('pLdmcleh')) {
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
    } else {
	$system = "American";
	$sep = ",";
	$point = ".";
    }

    # get the number
    #
    if (defined $ARGV[0]) {
	$num = $ARGV[0];
    } elsif ($html == 0) {
    # Web firewall
    #
    if ($html && length($num) > $big_input) {
	big_err();
    }

    # strip separators and whitespace
    #
    $num =~ s/[\s\Q$sep\E]+//g;

    # note if negative or positive
    #
    # We remove any leading - to optimize for the positive case.
    #
    if ($neg = ($num =~ /^-/)) {
	$num =~ s/^-//;
    }

    # strip leading 0's
    #
    if ($num =~ /^0/) {
	if ($num =~ /^00+$/) {
	    # deal with only 0's case
	    $num = "0";
	} else {
	    # strip off leading 0's
	    $num =~ s/^0+//;
	die "$0: numbers may have only one decimal $point\n";
    }

    # firewall
    #
    if ($num =~ /\Q$point\E.*\Q$point\E/o) {
	err("Numbers may have only one decimal $point.");
    }
    if ($num =~ /^$/) {
	$num = "0";
    }
	    die "$0: scientific numbers may only have a leading -, digits\n" .
    # and convert it into a long decimal value.
    #
    if ($num =~ /[eE]/) {
		"$sep's, leading 0's and whitespace characters are ignored.\n";
	        "Scientific numbers may only have a leading -, digits\n" .
		"an optional decimal $point (optionally followed by digits)\n" .
	    die "$0: scientific numbers must at least a digit before the e\n";
		"optional - and 1 more more digits after the e.  All\n" .
	$num = &exp_number($num, $point);
	$num = exp_number($num, $point, \$bias);

    # We did not have a number in scientific notation so we have no bias
    #
    } else {
	die "$0: A number may only have a leading -, digits and an " .
	    "optional decimal $point.  All $sep's and whitespace\n" .
	    "characters and leading 0's are ignored\n";
    #
    if ($num !~ /^[\d\Q$point\E]+$/o || $num =~ /^\Q$point\E$/) {
	err("A number may only have a leading -, digits and an " .
	       "optional decimal ``$point''.\n" .
	       "All 3 digit separators and" .
    # split into integer and fractional parts
	}
	print $cgi->p, "\n";
    if ($opt_p || $opt_L) {
	$preblock = 1;
    }

    # catch the case where we only want to enter a power of 10
	    die "$0: The power of 10 must be a non-negative integer.\n";
    if ($opt_p || $opt_l) {

       # only allow powers of 10 that are non-negative integers
       #
	   &power_of_ten(\$integer, $system);
	    err("The power must be a non-negative integer.");

       # print the name
       #
       } else {
	   power_of_ten(\$integer, $system, $bias);
	if ($opt_l) {
	    &print_number($sep, $neg, \$integer, $point, \$fract, 0);
    # print the number comma/dot separated
	    &print_number($sep, $neg, \$integer, $point, \$fract, 76);
    } elsif ($opt_c) {

	if ($opt_o) {
	    print_number($sep, $neg, \$integer, $point, \$fract, 0, $bias);
	} else {
	&print_name($neg, \$integer, \$fract, $system);
	}

    # otherwise print the first part of the response if allowed
    #
    } else {
	&trailer(0);
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
sub exp_number($$)
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
	    $int .= '0' x $exp;

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
	    $frac = ('0' x $exp) . $frac;

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


# print_number - print the number with ,'s or .'s
#
# given:
#	\$integer	integer part of the number
sub print_number($$\$$\$$)
#	\$fract		fractional part of number (or undef)
    my ($sep, $neg, $integer, $point, $fract, $linelen) = @_;	# get args
    my $wholelen;	# length of the integer part
    my $fractlen;	# length of the fractional part
    my $leadlen;	# length of digits, seperaotrs and - on 1st line
    my ($sep, $neg, $integer, $point, $fract, $linelen, $bias) = @_;
    my $intlen = 0;	# length of the integer part without bias
    my $fractlen = 0;	# length of the fractional part
    my $leadlen;	# length of digits, separators and - on 1st line
    my $fulllen;	# approximate length of the input
    if ($$integer eq "") {
    my $nonint_bias = 0;    # 1 => $bias is very large, process with care
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
    } elsif ($linelen > 0) {
	$linelen = int($linelen/4) * 4;
    } else {
	$linelen = 0;
    }

    # no line length specified (or value passed < 4) means just print it
    # on a single line

	    print $$integer, $point, $$fract, "\n";

		print $$fract;
	    print $$integer, "\n";
		    while (($bias -= $big_bias) > $big_bias) {
			print "0" x $big_bias;
		    }
		}
		print "0" x $bias;
	    }
	}

    # If we have a line length, we need to insert newlines after
	$wholelen = length($$integer);
	# determine the length of the integer part of the number
	#
	$wholelen = Math::BigInt->new($intlen);
	    #
	} else {
	    # warnings internal to the BigInt code with the
	    # division below.  We block these bogus warnings.
	    #
	    $^W = 0;
	    $leadlen += ($wholelen-1)/3;
	    $^W = $warn;
	}
	if ($neg) {
	    # account for - sign
	#
	# warnings internal to the BigInt code with the
	# modulus below.  We block these bogus warnings.
	#
	$^W = 0;
	$col = ($linelen - (($leadlen+1) % $linelen)) % $linelen;
	$^W = $warn;
	print " " x $col;

	# process a leading -, if needed
		# and the separators to line up in colums (particularly
	if ($neg) {
	    if (++$col >= $linelen) {
		# This could mean that we have a lone - in the 1st line
		# but there is nothing we can do about that if we want
		# the decimal point/comma to be at the end of a line
		# and the separators to line up in columns (particularly
		# along the right hand edge)
		print "-\n";
		$col = 1;
	    } else {
	$i = length($$integer) % 3;
		$i = ($intlen+2) % 3;
	    }
	    $^W = $warn;
	} else {
	print substr($$integer, 0, $i);
	$col += $i;
	# output , and 3 digits until whole number is exhusted
	    print substr($$integer, 0, $i), 0 x ($i-$intlen);
	while ($i < $wholelen) {
	    print substr($$integer, 0, $i);
	}

	# output , and 3 digits until whole number is exhausted
	#
	while ($i < $intlen) {

	    # output the separator, we add a newline if the line
	    # is at or beyond the limit
	    #
	    if (++$col >= $linelen) {
		print "$sep\n";
		$col = 1;
	    print substr($$integer, $i, 3);
	    #
	    if ($i+3 > $intlen) {
		print substr($$integer, $i, 3), 0 x ($i+3-$intlen);
	    } else {
		print "000";
		$col += 3;
	#
	    }

	# print the decimal point/comma followed by the fractional
	# part if needed
	#
	if (defined($$fract)) {

	    # print the rest of the faction in linelen chunks
		#
	    $fractlen = length($$fract);
	    for ($i = 0; $i < $fractlen; $i += $linelen) {
		print substr($$fract, $i, $linelen), "\n";


	# otherwise finish up the integer line
	} else {
	    print "\n";
		# print the rest of the faction in linelen chunks
		#
	    }
	}
    }

    # end of the number
# usage:
#	$num	number to construct

# latin_root - return the Latin root of a number
#
# given:
#	$num	   number to construct
sub latin_root($)
# form a name for 1000^($num+1), depending on American or European
    my $num = $_[0];	# number to construct
# The effect of $millia is to multiply $num by 1000^$millia.
#
sub latin_root($$)
{
    my ($num, $millia) = @_;	# get args
    my $numstr;	# $num as a string
    my @set3;	# set of 3 digits, $set3[0] is the most significant
    my $d3;	# 3rd digit in a set of 3
    my $l2;	# latin name for 2nd digit in a set of 3
    my $l1;	# latin name for 1st digit in a set of 3
    # If $bias is larger than $big_bias, then we cannot just treat
    # it like an integer.  In the case of the web, we bail.  In
    if ($num < @l_special) {
    #
    $nonint_millia = 1 if ($millia > $big_bias);

    # deal with small special cases for small values
    #
    if ($millia == 0 && $num < @l_special) {
    $num =~ s/[^\d]//g;
    $i = length($num);
    }

	@set3 = unpack("a3"x$len, $num);
    #
	@set3 = unpack("a"."a3"x($len-1), $num);
    $i = length($numstr);
    $len = int(($i + 2) / 3);
	@set3 = unpack("a2"."a3"x($len-1), $num);
	@set3 = unpack("a3"x$len, $numstr);
    } elsif ($i % 3 == 1) {
	@set3 = unpack("a"."a3"x($len-1), $numstr);
    #
    # We have to be careful about how we compute $millia+len-1
    # so that it will not become a floating value.
    #
    $millia_cnt = $millia + $len;
	    # warnings internal to the BigInt code with the
	    # decrement below.  We block these bogus warnings.
	    #
	    --$millia_cnt;
	}

	# do nothing if 000
	#
	if ($set3[$i] == 0) {
	    next;
	}

	# extract digits in the current set of 3
	#
	# The 100's place is a little bit tricky.  Normally the hundred names
	# end in a ``t'', however when we are dealing with the last set of
	# 3 and there is no tens or ones, then the ''t'' is thought to belong
	# to the final ``tillion'' or ``tillard''.
	#
	$d1 = substr($set3[$i], 2, 1);
	$l1 = (($d1 > 0) ? $l_unit[$d1] . $dash : "");

	$l2 = (($d2 > 0) ? $l_ten[$d2] . $dash : "");
	$d3 = substr($set3[$i], 0, 1);
	$l3 = (($d3 > 0) ? $l_hundred[$d3] .
			   (($i == $len-1 && $d1 == 0 && $d2 == 0) ? "" : "t") .
			   $dash : "");

	# print the 3 digits
	#	millia-tillion
	# We will skip the printing of the 3 digits if
	# we have just 001 in all but the lowest set of 3.
	# This results in no output do that we wind up with
	#	un-millia-tillion
	#
	if ($i == $len-1 || $d1 != 1 || $d2 != 0 || $d3 != 0) {
	#
	# instead of:
	#
	# add one the millia as needed
	#
	if ($i < $len-1) {
	    if ($opt_m && $i < $len-2) {
		print "millia^", $len-$i-1, "$dash";
		if ($millia_cnt > 1) {
		print "millia$dash" x ($len-$i-1);
		if ($nonint_millia) {
		    while (($millia_cnt -= $big_bias) > $big_bias) {
			print "millia$dash" x $big_bias;
		    }
		}
    # instead of the usual 'ti'.  This is decause we say:
	    }
	}
    }

    # For the case of ending in 1x we need to end in an 'i'
    # instead of the usual 'ti'.  This is because we say:
    #
    if ($d2 == 1) {
    #
    # instead of:
    #
    #	trecen-dec-tillion
    #
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
# usage:
#	$power		power of 1000

# Prints the name of 1000^$power.
# european_kilo - return the name of power of 1000 under European system
#
# given:
#	$power	power of 1000
#
# Prints the name of 1000^$power.
#
# The European system uses both "llion" and "lliard" suffixes for
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

    # We treat 0 as nothing
    } elsif ($power == 1) {
    if ($power == 0) {
	return;
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
}

# power_of_ten - just print name of a the power of 10
sub power_of_ten(\$$)
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
    # Convert $$power arg into BigInt format
    #
    $big = Math::BigInt->new($$power);

    # convert the power of 10 into a multipler and a power of 1000

    # If we gave -L, then we will assume that we are dealing with
    #
    $big = Math::BigInt->new($$power);
    if ($opt_L) {
    # convert the power of 10 into a multiplier and a power of 1000
	# under -L, we deal with powers of 1000 above 1000
	    $big *= 10;
	$kilo_power = $big + 1;
	    $big *= 100;
	# under -L, our miltiplier name is always one

	# under -l, we deal with powers of 1000 above 1000
	#
	$kilo_power = $big;

		       "10\n" .
		       "of 10 at this time.  Try using Latin powers or enter" .
	# convert power of 10 into power of 1000
	$kilo_power = $big / 3;
	# bdiv below.  We block these bogus warnings.
	# print the multipler name
	$^W = 0;
	$mod3 = ($big % 3);
	$^W = $warn;
	if ($mod3->bcmp($one) < 0) {
	$^W = $warn;
	} elsif ($mod3->bcmp($one) == 0) {

	# print the multiplier name
	#
	if ($mod3 < 1) {
	    print "one";
	} elsif ($mod3 == 1) {
    # To avoid passing the BigInt issue onto &american_kilo() and
    # &european_kilo() we will to our own suffix generation here
    # and bypass them.  Unfortunatly we must duplicate code again
    # as a result.

	    print "ten";
	} else {
	    print "one hundred";
    if ($kilo_power->bcmp($one) < 0) {
    }

    # A zero kilo_power means that we only have 1, 10 or 100
    # and so there is nothing else to print.
    #
    } elsif ($kilo_power->bcmp($one) == 0) {
	# nothing else to print

    # We must treat a kilo_power of 1 as a special case
    # because 'thousand' does not have a Latin root base.
    #
    } elsif ($kilo_power == 1 && $biasmillia == 0) {
	print " thousand";
	&latin_root($kilo_power-1);
    # print the name based on the American name system
    #
    } elsif ($system eq 'American') {

	print " ";
	latin_root($kilo_power-1, $biasmillia);
	# is even or odd.
	$mod2 = $kilo_power % 2;
	$kilo_power /= 2;
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
#	\$integer	intger part of the number

#	$system	the number system ('American' or 'European')
#
sub print_name($\$\$$)
#	\$fract		fractional part of number (or undef)
    my ($neg, $integer, $fract, $system) = @_;	# get args
sub print_name($$$$$)
    my $bias_mod3;	# bias % 3
    my $millia;		# millia arg, power of 1000 for a given set f 3
    my $intstr;		# integer as a string
    my $fractlen = 0;	# length of the fractional part
    my $fulllen;	# approximate length of the input
    # If $bias is larger than $big_bias, then we cannot just treat
    # it like an integer.  In the case of the web, we bail.  In
    # the case of non-web output, we have to perform BigInt processing.
    #
    $nonint_bias = 1 if ($bias < -$big_bias || $bias > $big_bias);

    # process a leading -, if needed
    #
    if ($neg) {
	print "negative ";
    }

	    $intstr .= "0";
	} elsif ($bias_mod3 == 2) {
    $intlen = length($$integer);
	}
	    $fulllen -= $bias;
	}
	if ($fulllen > $big_name) {
	    big_err();
    $set3 = substr($$integer, 0, $indx);
    &print_3($set3);

    # print the highest order set, which may be partial
    #
	&american_kilo($cnt3);
    if ($system eq 'American') {
	&european_kilo($cnt3);
    } else {
	if ($bias > 0) {
	    european_kilo($millia+$cnt3);
	} else {
	    european_kilo($cnt3);
	$set3 = substr($$integer, $indx, 3);
    }

	if (defined $opt_l) {
    #
    while (--$cnt3 >= 0) {
	$set3 = substr($intstr, $indx, 3);
	$indx += 3;
	&print_3($set3);
	if ($cnt3 > 0) {
	    print ", ";
	} else {
		&american_kilo($cnt3);
	    if ($system eq 'American') {
		&european_kilo($cnt3);
	    } else {
		if ($bias > 0) {
		    european_kilo($millia+$cnt3);
		} else {
		    european_kilo($cnt3);
		}
	    }

    # print after the decimal point if needed
    #
	if (defined $opt_l) {
	    print " ";
	} else {
        my $len;	# length of current line
	my $line;	# current line being formed

	# mark the decimal point/comma
	#
	if (!$opt_o) {
		    $len += $diglen;
		} else {
		    print "\n$zero";
		    $len = $diglen - 1;
		}
	    if (defined $opt_l) {
		print " ";
	for ($i=0; $i < length($$fract); ++$i) {
		print "\n";
		    print " $dig";
	    print  $digit[ substr($$fract, $i, 1) ];
		    $len += $diglen;
		} else {
		    print "\n$dig";
		    $len = $diglen - 1;
		}
	    }
	}
    }
# usage:
}


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
	    }
	    $name_3 .= $digit[$num];
	}

	# save the 3 digit name
	#
	$english_3[$number] = $name_3;
    }

# cgi_form - print the CGI HTML form
    #
# usage:
#	\$q	CGI object
#
# returns:
#	$num	input value

sub cgi_form(\$\$)
# cgi_form - print the CGI/HTML form
    my ($q, $num) = @_;		# CGI object

#
# returns:
#	$num	input value
#
sub cgi_form()
	"latin" => " Latin power (1000^(number+1))"
    # radio label sets
    #
    my %input_label = (
	"digit" => " Decimal digits"
	"exp" => " Power of 10",
	"latin" => " Latin power (1000^number)"
    );
    my %output_label = (
	"name" => " English name",
	"digit" => " Decimal digits if input is just a number"
    );
	"power" => " millia^7"
	"usa" => " American system",
	"europe" => " European system"
    );
    my %millia_label = (
	"dup" => " milliamillia...",
	"power" => " millia^7 (compact form)"
    print $q->header,
	  $q->start_html('title' => 'The Name of a Number',
			 'bgcolor' => '#80a0c0'),
	  $q->h1('The Name of a number'),
	  $q->p,
	  "See the ",
	  $q->a({'HREF' => "/chongo/number/example.html"},
		  "example / help"),
	  " page for an explination of the options below.\n",
	  $q->p,
	  $q->start_form,
	  "Type of input:",
	  "&nbsp;" x 4,
	  $q->radio_group('name' => 'input',
			  'values' => ['number', 'exp', 'latin'],
			  'labels' => \%input_label,
			  'default' => 'number'),
	  $q->br,
	  "Type of output:",
	  "&nbsp;" x 2,
	  $q->radio_group('name' => 'output',
			  'values' => ['name', 'digit'],
			  'labels' => \%output_label,
			  'default' => 'name'),
	  $q->br,
	  "Name system:",
	  "&nbsp;" x 4,
	  $q->radio_group('name' => 'system',
			  'values' => ['usa', 'europe'],
			  'labels' => \%system_label,
			  'default' => 'usa'),
	  $q->br,
	  "Millia styie:",
	  "&nbsp;" x 8,
	  $q->radio_group('name' => 'millia',
			  'values' => ['dup', 'power'],
			  'labels' => \%millia_label,
			  'default' => 'dup'),
	  $q->br,
	  "Dash styie:",
	  "&nbsp;" x 10,
	  $q->radio_group('name' => 'dash',
			  'values' => ['nodash', 'dash'],
			  'labels' => \%dash_label,
			  'default' => 'nodash'),
	  $q->p,
	  $q->b('<FONT SIZE="+1">Enter a number:</FONT>'),
	  $q->br,
	  $q->textarea('name' => 'number',
		       'rows' => '10',
		       'columns' => '60'),
	  $q->p,
	  $q->submit(name=>'Name that number'),
	  " &nbsp;&nbsp;\n",
	  $q->reset('name' => 'Clear'),
	  $q->end_form;
    print $cgi->textarea(-name => 'number',
		         -rows => '10',
		         -columns => '60'), "\n";
    print $cgi->p, "\n";
    print $cgi->submit(name=>'Name that number'), "\n";
    print $cgi->end_form, "\n";

    if ($q->param()) {

	# determine the input mode
	#
	if (defined($q->param('input'))) {
	    if ($q->param('input') eq "exp") {
		$opt_p = 1;	# assume -p (power of 10)
	    } elsif ($q->param('input') eq "latin") {
		$opt_L = 1;	# assume -L (1000 ^ (number+1))
	    }
    #
	if ($cgi->param('input') eq "exp") {
	# determine the output mode
	#
	if (defined($q->param('output')) && $q->param('output') eq "digit") {
	    $opt_c = 1;		# assume -c (comma/dot decimal)
	}
    # determine the output mode
	# determine the system
	#
	if (defined($q->param('system')) && $q->param('system') eq "europe") {
	    $opt_e = 1;		# assume -e (European system)
	}
    # determine the system
	# determine the millia style
	#
	if (defined($q->param('millia')) && $q->param('millia') eq "power") {
	    $opt_m = 1;		# assume -m (compact millia method)
	}

	# determine the dash method in names
	#
	if (defined($q->param('dash')) && $q->param('dash') eq "dash") {
	    $opt_d = 1;		# assume -d (use -'s in names)
	}

	# get ready to print the value
	#
	print $q->hr,
	      $q->p;
	if (defined($opt_c)) {
	    print "\nDecimal value:\n";
	} else {
	    print "\nName of number:\n";
	}
	print "\n<BLOCKQUOTE>\n",
	      $q->b;
    # determine the millia style
    # We have just the initial display.  There is no input value.
    # Just print the trailer and exit, do not return.
    if (defined($cgi->param('millia')) &&
    } else {
	print "\n<BLOCKQUOTE>\n",
	      $q->b,
	      "<PRE>";
	&trailer(0);
	exit(0);
    }

    # determine the dash method in names
    #
    return $q->param('number');
	$opt_d = 1;		# assume -d (use -'s in names)
    }

    # return the number
# usage:
#	&trailer()
}

# if surpressed.
#
# given:
#	$arg	1 => suppress message about obtaining the source
#
# If the arg passed is 1, then the message about obtaining the source
# if suppressed.
#
    print "</PRE>\n</B>\n</BLOCKQUOTE>\n<HR>\n<P>\n";

    # section off with a line
    #
    if ($html == 1) {
	print "<HR>\n<P>\n";
	The <A HREF="/chongo/number/number">source</A> for this CGI
	script is available.
	Save it as either <B>number.cgi</B> and/or <B>number</B>.
	<p>
	If you run this program as <B>number</B> (i.e., without the <B>.cgi</B>
	extension),
	then it runs as normal program without all of the CGI/HTML stuff.
	In normal program mode, the program does not enforce an arbitrary
	size limit.
	Try <B>./number -h</B> for more information.
        <B>number.cgi</B> or <B>number</B>.
        The CGI script <B>number.cgi</B> operates as it is doing now.<BR>
	The Perl script <B>number</B> reads a number from standard input,
	has no size limits<BR>
	and does not perform any CGI/HTML actions.
	Try <B>./number -h</B> for more info.
	<P>
	<HR>
    </P> <blockquote>
    <A HREF="http://reality.sgi.com/chongo/index.html">chongo</A>
    &lt; was here &gt;
    Brought to you by:
    </P> <BLOCKQUOTE>
    Landon Curt Noll
    <BR>
    <A HREF="http://www.isthe.com/chongo/index.html">chongo</A>
    &lt; was here &gt;
	print $cgi->hr, "\n";
	print $cgi->p, "\n";
    }
    print $cgi->b("SORRY!"), "\n", $msg, "\n";
    trailer(0);
    exit(1);
}
