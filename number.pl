#!/usr/bin/perl -T
#!/usr/bin/perl -wT
#  @(#} $Revision: 1.28 $
#
# number - print the English name of a number in non-HTML form
#
# usage:
#	number [-p] [-L] [-d] [-m] [-c] [-l] [-e] [-h] [number]
#
#	-p	input is a power of 10
#	-L	input is a Latin power of 1000
#	-d	add dashes to help with pronunciation
#	-m	output name in a more compact exponential form
#	-c	output number in comma/dot form
#	-l	output number on a single line
#	-e	use European instead of American name system
#	-h	print a help message only
#
# If number is omitted, then it is read from standard input.
#
# Be sure to see:
#
#	http://reality.sgi.com/chongo/number/number.html
#
# for examples/help as well as the latest version of this code.
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
# as well as thanks to these people for their bug reports on earler versions:
#
#	Dr K.M. Briggs		Fredrik Mansfeld
#	kmb28 at cus.cam.ac.uk	fredrik at abaris.se
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
#use Getopt::Std;
use Getopt::Long;
# CGI requirements
use CGI qw(:standard);

# version
my $version = '$Revision: 1.28 $';

# GetOptions argument
#
my %optctl = (
    "p" => \$opt_p, "L" => \$opt_L, "d" => \$opt_d, "m" => \$opt_m,
    "c" => \$opt_c, "l" => \$opt_l, "e" => \$opt_e, "h" => \$opt_h
);

# Warning state
my $warn = $^W;

# We setup this arbitrary limit so that people to not enter
# very large numbers and drive that server crazy.  The algoritm
# used has no limit so we pick an arbitrary limit.
#
# This digit count is not exact, but serves as a limiter on
# the length of input as well as the exponent allowed in E notation.
#
# XXX - need to re-evaluate this in light of the use of the $bias BigInt
#
my $too_big = "5000";   # too many digits for the web

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
my $cgi = 0;		# CGI object, if invoked as a CGI script

# usage and help
#
my $usage = "number [-p] [-L] [-d] [-m] [-c] [-l] [-e] [-h] [[--] number]";
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
	--	the arg that follows is a number (useful if number is <0)

    If number is not given on the command line it is read from standard
    input.

    All whitespace (including newlines), commas and periods
    are ignored, with the exception of a single (optinal)
    decimal point (or decimal comma if european name system),
    which if found will be processed.  In the case of reading from
    standard input, all valid data found on standard input will be
    considered as if it were a single number.

    A number may be either in decimal or in scientific notation (e.g.,
    2.5e100).  Negative and floating point numbers are allowed.
    Be careful when using negative on the command line.  One must give
    an -- argument so as to not confuse command parsing.  E.g.:

	./number -- -123

    Updates from time to time are made to this program.
    See http://reality.sgi.com/chongo/number/number.html for updates.

    You are using $version.

    BUGS: On the command line, numbers in scientific notation with
	  very large or very negative exponents could fail to produce 
	  correct results.  Often these failures occur when the exponent
	  is >= 2^31 or <= -2^31.  This bug will be addressed in a
	  future version ... when scientific notation values are
	  no longer converted into decimal numbers internally.

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
    my $bias;		# power of 10 bias (as BigInt)
    my $neg;		# 1 => number if < 0

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
	$cgi = new CGI;
	if (cgi_error()) {
	    print "Content-type: text/plain\n\n";
	    print "Your browser sent bad or too much data!\n";
	    print "Error: ", cgi_error(), "\n";
	$num = &cgi_form();
	}
	if (! defined $num) {
	    print $cgi->p, "\n";
	    trailer(0);
	    exit(0);
	}

	&error("usage: $0 $usage\n");
    #
    # NOTE: The -0 thru -9 are hacks to deal with negative numbers
    #	    on the command line.
    #
    } elsif (!GetOptions(%optctl)) {
    if (defined($opt_h)) {
	exit(1);
    }

    # Print help if that is all that is required
    # -c conflicts with -L and -p
    if ($opt_h) {
    if (defined($opt_c) && (defined($opt_L) || defined($opt_p))) {
	exit(0);
	    &error("-c conflicts with -L and -p");

	    &error("You may only print decimal digits when the input is " .
	        "just a number.\n");
    if ($opt_c && ($opt_l || $opt_p)) {
	if ($html == 0) {
	    err("-c conflicts with either -l and/or -p");
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
    if ($html == 1 && length($num) >= $too_big) {
	&big_error();
    }
	    $num =~ s/^0+//;
	&error("Numbers may have only one decimal $point.\n");
    }

    # firewall
    #
    if ($num =~ /\Q$point\E.*\Q$point\E/o) {
	err("Numbers may have only one decimal $point.");
    }
    if ($num =~ /^$/) {
	$num = "0";
    }
	    &error(
    # If scientific (e or E notation), verify format
    # and convert it into a long decimal value.
    #
    if ($num =~ /[eE]/) {
		"$sep's, leading 0's and whitespace characters are ignored.\n");
	        "Scientific numbers may only have a leading -, digits\n" .
		"an optional decimal $point (optionally followed by digits)\n" .
	    &error("Scientific numbers must at least a digit before the e.\n");
		"optional - and 1 more more digits after the e.  All\n" .
	$num = &exp_number($num, $point, \$bias);
	    err("Scientific numbers must at least a digit before the e.");
	}
	$num = exp_number($num, $point, \$bias);

    # We did not have a number in scientific notation so we have no bias
    #
    } else {
	&error("A number may only have a leading -, digits and an " .
	       "optional decimal $point.  All $sep's and whitespace\n" .
	       "characters and leading 0's are ignored.\n");
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
	    &error("The power must be a non-negative integer.\n");
    if ($opt_p || $opt_l) {

       # only allow powers of 10 that are non-negative integers
       #
	   # XXX - need to oass in the $bias BigInt
	   &power_of_ten(\$integer, $system);
	    err("The power must be a non-negative integer.");

       # print the name
       #
       } else {
	   power_of_ten(\$integer, $system, $bias);
	if ($opt_l) {
	    # XXX - need to oass in the $bias BigInt
	    &print_number($sep, $neg, \$integer, $point, \$fract, 0);
    # print the number comma/dot separated
	    # XXX - need to oass in the $bias BigInt
	    &print_number($sep, $neg, \$integer, $point, \$fract, 76);
    } elsif ($opt_c) {

	if ($opt_o) {
	    print_number($sep, $neg, \$integer, $point, \$fract, 0, $bias);
	} else {
	# XXX - need to oass in the $bias BigInt
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
    #
    exit(0);
}

# exp_number - convert a scientific notation number into an number
#
# Given a number in scientific notation, we will attempt to adjust
# the position of the decimal point/comma so as to reduce the
# scientific exponent.  For example:
#
#	1.234e2
#
# would become:
#
#	123.4		with a bias of 0
#
# It is not always possible to fully adjust the scientific exponent
# into a 0 bias.  For example:
#
#	12345.6e-10
#
# would become:
#
#	.123456		with a bias of -5
#
# This function will not adjust the decimal point/comma to beyond
# the left or right hand side of the digit string.
#
# given:
#	$num	contains a string with something like -3.5e70 or
#		.5e50 or 4E50 or 4.E-49
sub exp_number($$\$)
#	\$bias	adjusted power of ten bias as a BigInt
#
# returns:
#	adjusted non-scientific notation string
#
sub exp_number($$$)
{
    my ($num, $point, $bias) = @_;	# get args
    my $expstr;	# base 10 exponent (value after the E) as a string
    my $exp;	# base 10 exponent (value after the E) as a BigInt
    my $lead;	# lead digits (before the E)
    my $int;	# integer part of lead
    my $frac;	# fractional part of lead

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

	# limit the size of the input in a arbitrary way when in CGI/HTML mode
	#
	if ($html == 1 && $exp >= $too_big) {
	    &big_error();
	}

    # If we need to move the decimal point/comma to the right, then
    # we do so by moving digits from $fract onto the end of $int and
    # adding more 0's onto the end of $int as needed.
    #
    if ($exp > 0) {

	# If we have more exp than $frac digits, then just
	# tack the $frac onto the end of the $int part.  This
	# will result in power of ten bias > 0.
	#
	if (length($frac) <= $exp) {

	    # move all $frac digits to the left of decimal point/comma
	    #
	    $int .= $frac;
	    $$bias = $exp - length($frac);
	    $frac = "";

	# we have fewer exp than $frac digits, so we will move
	    $$bias = 0;
	#
	} else {
	    # we use $expstr because we know that it is a small value
	    $int .= substr($frac, 0, $expstr);
	    $frac = substr($frac, $expstr);
	    $$bias = $zero;
	}

	# limit the size of the input in a arbitrary way when in CGI/HTML mode
	#
	if ($html == 1 && $exp >= $too_big) {
	    &big_error();
	}

    # If we need to move the decimal point/comma to the left, then
    # we do so by moving digits from the end of $int onto the front
    # if $frac and adding more 0's on the front of $frac as needed.
    #
    } elsif ($exp < 0) {

	# If we have more exp than $int digits, then we just
	# tack the $int part onto the front of the $int part
	# and set $int to 0.  This will result in a power of
	    $$bias = $exp + length($frac);
	#
	if (length($int) <= -$exp) {

	    # move all $int digits to the right of decimal point/comma
	    #
	    $$bias = $exp + length($int);
	    $frac = $int . $frac;
	    $int = "0";

	# we have fewer exp than $int digits, so we will move
	    $$bias = 0;
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
    }
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
    print "\n";
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
    return;
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
	&error(
	    "Negative and fractional powers of 1000 not supported: $power\n");
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
    }
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
	&error(
	    "Negative and fractional powers of 1000 not supported: $power\n");
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

    # Odd roots use "lliard"
    #
    } elsif ($power % 2 == 1) {
	&latin_root(int($power/2));
	print "lliard";
	# Odd roots use "lliard"
	#
	} else {
	    latin_root($big, $zero);
	    print "lliard";
	}
    }
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

	# Odd roots use "lliard"
	#
	} else {
	    print " ";
	    latin_root($kilo_power, $biasmillia);
	    print "lliard";
	}
    }
    print "\n";
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
    print "\n";
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

	&error("print_3 called with arg not in [0,999] range: $number\n")
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

    # print the 3 digit name
    #
    print $english_3[$number];
}

sub cgi_form(\$)
# cgi_form - print the CGI/HTML form
#
# returns:
#	$num	input value
#
sub cgi_form()
	"latin" => " Latin power (1000^(number+1))"
    # radio label sets
    #
    my %input_label = (
	"number" => " Just a number",
	"exp" => " Power of 10",
	"latin" => " Latin power (1000^number)"
    );
    my %output_label = (
	"name" => " English name",
	"digit" => " Decimal digits if input is just a number"
    );
    my %system_label = (
	"usa" => " American system",
	"europe" => " European system"
    );
    my %millia_label = (
	"dup" => " milliamillia...",
	"power" => " millia^7 (compact form)"
    print $cgi->header,
	  $cgi->start_html('title' => 'The Name of a Number',
			 'bgcolor' => '#80a0c0'),
	  $cgi->h1('The Name of a number'),
	  $cgi->p,
	  "See the ",
	  $cgi->a({'HREF' => "/chongo/number/example.html"},
		  "example / help"),
	  " page for an explination of the options below.\n",
	  $cgi->p,
	  $cgi->start_form,
	  "Type of input:",
	  "&nbsp;" x 4,
	  $cgi->radio_group('name' => 'input',
			  'values' => ['number', 'exp', 'latin'],
			  'labels' => \%input_label,
			  'default' => 'number'),
	  $cgi->br,
	  "Type of output:",
	  "&nbsp;" x 2,
	  $cgi->radio_group('name' => 'output',
			  'values' => ['name', 'digit'],
			  'labels' => \%output_label,
			  'default' => 'name'),
	  $cgi->br,
	  "Name system:",
	  "&nbsp;" x 4,
	  $cgi->radio_group('name' => 'system',
			  'values' => ['usa', 'europe'],
			  'labels' => \%system_label,
			  'default' => 'usa'),
	  $cgi->br,
	  "Millia style:",
	  "&nbsp;" x 8,
	  $cgi->radio_group('name' => 'millia',
			  'values' => ['dup', 'power'],
			  'labels' => \%millia_label,
			  'default' => 'dup'),
	  $cgi->br,
	  "Dash style:",
	  "&nbsp;" x 10,
	  $cgi->radio_group('name' => 'dash',
			  'values' => ['nodash', 'dash'],
			  'labels' => \%dash_label,
			  'default' => 'nodash'),
	  $cgi->p,
	  $cgi->b('<FONT SIZE="+1">Enter a number:</FONT>'),
	  $cgi->br,
	  $cgi->textarea('name' => 'number',
		         'rows' => '10',
		         'columns' => '60'),
	  $cgi->p,
	  $cgi->submit(name=>'Name that number'),
	  $cgi->end_form;
    print $cgi->textarea(-name => 'number',
		         -rows => '10',
		         -columns => '60'), "\n";
    print $cgi->p, "\n";
    print $cgi->submit(name=>'Name that number'), "\n";
    print $cgi->end_form, "\n";

    if ($cgi->param()) {

	# determine the input mode
	#
	if (defined($cgi->param('input'))) {
	    if ($cgi->param('input') eq "exp") {
		$opt_p = 1;	# assume -p (power of 10)
	    } elsif ($cgi->param('input') eq "latin") {
		$opt_L = 1;	# assume -L (1000 ^ (number+1))
	    }
    #
	if ($cgi->param('input') eq "exp") {
	# determine the output mode
	#
	if (defined($cgi->param('output')) &&
	    $cgi->param('output') eq "digit") {
	    $opt_c = 1;		# assume -c (comma/dot decimal)
	}
    # determine the output mode
	# determine the system
	#
	if (defined($cgi->param('system')) &&
	    $cgi->param('system') eq "europe") {
	    $opt_e = 1;		# assume -e (European system)
	}
    # determine the system
	# determine the millia style
	#
	if (defined($cgi->param('millia')) &&
	    $cgi->param('millia') eq "power") {
	    $opt_m = 1;		# assume -m (compact millia method)
	}

	# determine the dash method in names
	#
	if (defined($cgi->param('dash')) && $cgi->param('dash') eq "dash") {
	    $opt_d = 1;		# assume -d (use -'s in names)
	}

	# get ready to print the value
	#
	print $cgi->hr,
	      $cgi->p;
	if (defined($opt_c)) {
	    print $cgi->b("Decimal value:");
	} else {
	    print $cgi->b("Name of number:");
	}
	print "\n<BLOCKQUOTE>",
	      "<PRE>";
    # determine the millia style
    # We have just the initial display.  There is no input value.
    # Just print the trailer and exit, do not return.
    if (defined($cgi->param('millia')) &&
    } else {
	print "\n<BLOCKQUOTE>\n",
	      "<PRE>";
	&trailer(0);
	exit(0);
    }

    # determine the dash method in names
    #
    if (defined($cgi->param('dash')) && $cgi->param('dash') eq "dash") {
	$opt_d = 1;		# assume -d (use -'s in names)
    }

    # return the number
    #
#	$arg	1 => supress message about obtaining the source
}

# if surpressed.
#
# given:
#	$arg	1 => suppress message about obtaining the source
#
# If the arg passed is 1, then the message about obtaining the source
# if suppressed.
#
    print "</PRE>\n</BLOCKQUOTE>\n<HR>\n<P>\n";

    # section off with a line
    #
    if ($html == 1) {
	print "<HR>\n<P>\n";
	The <A HREF="/chongo/number/number.cgi.txt">source</A> for this CGI
	script is available. Save it as either the filename<BR>
    if (defined($arg) && $arg == 0) {
	print <<END_OF_HTML;
	<P>
	The
	<A HREF="http://www.isthe.com/chongo/tech/math/number/number">source</A>
	for this CGI script is available. Save it as either the filename<BR>
        <B>number.cgi</B> or <B>number</B>.
        The CGI script <B>number.cgi</B> operates as it is doing now.<BR>
	The Perl script <B>number</B> reads a number from standard input,
	has no size limits<BR>
	and does not perform any CGI/HTML actions.
	Try <B>./number -h</B> for more info.
	<P>
	<HR>
END_OF_HTML
    <A HREF="http://reality.sgi.com/chongo/index.html">chongo</A>
    &lt; was here &gt;
    Brought to you by:
    </P> <BLOCKQUOTE>
    Landon Curt Noll
    <BR>
    <A HREF="http://www.isthe.com/chongo/index.html">chongo</A>
    &lt; was here &gt;
    <STRONG>/\\oo/\\</STRONG>
    </BLOCKQUOTE>

# big_error - print a too big error and exit
#
sub big_error()
}


# big_err - print a too big error and exit
    print "</PRE>\n<P>\n";
    # close off input
    #
    if ($preblock) {
	print $cgi->p, "\n";
	print "</PRE>\n</BLOCKQUOTE>\n";
	  "&nbsp;&nbsp;We have imposed an arbitrary size limit on",

    # print too big error
    #
    print $cgi->p,
	  "on the size of the number we would print.  Otherwise someone\n",
	  "could enter a number such as <TT>1e1000000000</TT> causing\n",
	  "the server to flood the network with lots of data ... assuming\n",
	  "we had the memory to form the print buffer in the first place!\n",
	  $cgi->p,
	  "You have 4 choices:\n",
	  "<ol>\n<li> Enter a number that is ",
	  "less than $too_big characters in length.\n",
	  $cgi->p,
	  "<li> Compute a Latin power of a number that is ",
	  "less than $too_big characters in length.\n",
	  $cgi->p,
	  "<li> Raise 10 to a power where the exponent is ",
	  "less than $too_big characters in length.\n",
	  $cgi->p,
	  "<li> You may download the\n",
	  $cgi->a({'href' => "/chongo/number/number.cgi.txt"},
	  "If none of those options are what you want/need, you can\n",
	  "run this program on your own computer in the non-CGI mode.\n",
	  " Save it as either the filename ",
	  $cgi->br,
	  " and run it yourself.\n",
	  $cgi->p,
	  "If you do download the\n",
	  $cgi->a({'href' => "/chongo/tech/math/number/number"},
		  "source"),
	  " save it as either the filename ",
	  " operates as it is doing now.",
	  $cgi->br,
	  " or ",
	  $cgi->b("number"),
	  ".",
	  $cgi->br,
	  " The CGI script ",
	  $cgi->b("number.cgi"),
	  $cgi->p,
	  "NOTE: &nbsp;Numbers entered in scientific notation are currently",
	  " expanded into the full decimal form prior to any",
	  " $too_big character length checking.\n",
	  " operates as it is doing now with size limits.",
    &trailer(1);
	  $cgi->b("number"),
	  " reads a number from standard input, has no size limits",
	  "and does not perform any CGI/HTML actions.",
	  "</ol>\n",
# error - report an error in CGI/HTML or die form
    trailer(1);
    exit(1);
}

sub error($)
# err - report an error in CGI/HTML or die form
#
# given:
#	$msg	the message to print
#
    if ($html == 0) {
	die $msg;
    #
    if ($html == 0 || $cgi == 0) {
	if ($html != 0) {
	    print "Content-type: text/plain\n\n";
    print $cgi->p,
	  $cgi->b("SORRY! "),
	  $msg;
    &trailer(0);
	print $cgi->p, "\n";
	print $cgi->hr, "\n";
	print $cgi->p, "\n";
    }
    print $cgi->b("SORRY!"), "\n", $msg, "\n";
    trailer(0);
    exit(1);
}
