#!/usr/bin/perl -w
#!/usr/bin/perl -wT
#  @(#} $Revision: 2.20 $
#
# number - print the English name of a number of any size
#
# usage:
#	number [-p] [-l] [-d] [-m] [-c] [-o] [-e] [-h] [number]
#
#	-p	input is a power of 10
#	-l	input is a Latin power (1000^x)
#	-d	add dashes to help with pronunciation
#	-m	output name in a more compact exponential form
#	-c	output number in comma/dot form
#	-o	output number on a single line
#	-e	use European instead of American name system
#	-h	print a help message only
#
# If number is omitted, then it is read from standard input.
#
# When run as:
#
#	number.cgi
#
# then it will act like a CGI script with suitable size limits for
# web applications.
#
# When run as:
#
#	number	(or number.pl or anything not ending in .cgi)
#
# then it will run without the web/CGI size limitations.
#
# Be sure to see:
#
#	http://www.isthe.com/chongo/tech/math/number/number.html
#
# For an example of names of large numbers, see:
#
#	http://www.isthe.com/chongo/tech/math/prime/mersenne.html
#
# for examples/help as well as the latest version of this code.
#
# Copyright (c) 1998-2003 by Landon Curt Noll.  All Rights Reserved.
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
#	Jeff Drummond
#	jjd at sgi.com
#
# as well as thanks to these people for their bug reports on earlier versions:
#
#	Dr K.M. Briggs			Fredrik Mansfeld
#	kmb28 at cus.cam.ac.uk		fredrik at abaris.se
#
# Comments, suggestions, bug fixes and questions about these routines
# are welcome.  Send EMail to the address given below.
#
# Happy bit twiddling,
#
#	Landon Curt Noll
#	http://www.isthe.com/chongo
#
# chongo was here	/\../\
#

# requirements
#
use strict;
use Math::BigInt;
use vars qw($opt_p $opt_l $opt_d $opt_m $opt_c $opt_o $opt_e $opt_h);
use Getopt::Long;

# version
my $version = '$Revision: 2.20 $';

# CGI / HTML variables
#
my $html = 0;		# 1 ==> be are being invoked as a CGI script
my $cgi = 0;		# CGI object, if invoked as a CGI script
my $preblock = 0;	# 1 ==> we have output <BLOCKQUOTE><PRE>
if ($0 =~ /\.cgi$/) {
    $html = 1;
    use CGI qw(:standard :cgi-lib use_named_parameters -debug);
}

# GetOptions argument
#
my %optctl = (
    "p" => \$opt_p, "l" => \$opt_l, "d" => \$opt_d, "m" => \$opt_m,
    "c" => \$opt_c, "o" => \$opt_o, "e" => \$opt_e, "h" => \$opt_h
);

# Warning state
my $warn = $^W;

# We setup this arbitrary limit so that people to not enter
# very large numbers and drive that server crazy.  The algorithm
# used has no limit so we pick an arbitrary limit.
#
my $big_input = 32768;		# too many input digits for the web
my $big_latin_power = 100000;	# 1000^big_latin_power is limit for the web
my $big_decimal = 1000000;	# don't expand >$big_decimal digits on the web
my $big_digits = $big_input;	# too many digits to produce a name for the web
my $big_timeout = 10;		# max time to do anything
$SIG{ALRM} = sub { err("timeout"); };

# For DOS (Denial Of Service) protection prevent file uploads and
# really big "POSTS"
#
$CGI::POST_MAX = $big_input + 1024;	# limit post size to max digits + 1k
$CGI::DISABLE_UPLOADS = 1;		# no uploads

# We have optimizations that allow us to treat a large power of 10 bias
# (due to conversion of a very large scientific notation number) in
# a different fashion from a small bias.
#
# This value must be able to be be represented as an integer (say < 2^31).
# In practive this should be even smaller.
#
my $big_bias = 1000;		# a big bias (should be < 2^31).

# misc BigInt
#
my $two = Math::BigInt->new("2");
my $three = Math::BigInt->new("3");
my $eight = Math::BigInt->new("8");
my $neg_eight = Math::BigInt->new("-8");
my $ten = Math::BigInt->new("10");
my $hundred = Math::BigInt->new("100");
my $five_hundred = Math::BigInt->new("500");

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
my @digits = qw(zero one two three four five six seven eight nine);
my @tens = qw(zero ten twenty thirty forty
	      fifty sixty seventy eighty ninety);
my @teens = qw(ten eleven twelve thirteen fourteen
	       fifteen sixteen seventeen eighteen nineteen);

# usage and help
#
my $usage = "number [-p] [-l] [-d] [-m] [-c] [-o] [-e] [-h] [[--] number]";
my $help = qq{Usage:

    $0 $usage

	-p	input is a power of 10
	-l	input is a Latin power (1000^x)
	-d	add dashes to help with pronunciation
	-m	output name in a more compact exponentiation form
	-c	output number in comma/dot form
	-o	output number on a single line
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
    See http://www.isthe.com/chongo/tech/math/number/number.html
    for updates.

    You are using $version.

    chongo <number-mail at asthe dot com> was here /\\../\\
};

# forward declatations
#
sub exp_number($$$);
sub print_number($$$$$$$);
sub latin_root($$);
sub american_kilo($);
sub european_kilo($);
sub power_of_ten($$$);
sub print_name($$$$$);
sub print_3($);
sub cgi_form();
sub trailer($);
sub big_err();
sub err($);

# signal processing
#
$SIG{PIPE} = sub { exit(2); };

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
    my $bias;		# power of 10 bias (as BigInt) during de-sci conversion
    my $neg;		# 1 => number if < 0

    # setup
    #
    select(STDOUT);
    $| = 1;

    # set the defaults
    #
    $opt_p = 0;
    $opt_l = 0;
    $opt_d = 0;
    $opt_m = 0;
    $opt_c = 0;
    $opt_o = 0;
    $opt_e = 0;
    $opt_h = 0;

    # determine if we are CGI based
    #
    if ($html) {

	# CGI setup
	#
	alarm($big_timeout);
	$cgi = new CGI;
	if (cgi_error()) {
	    print "Content-type: text/plain\n\n";
	    print "Your browser sent bad or too much data!\n";
	    print "Error: ", cgi_error(), "\n";
	    exit(1);
	}
	$cgi->use_named_parameters(1);

	# print CGI form
	#
	$num = cgi_form();

	# If no number (as displayed the blank form), just exit
	#
	if (! defined $num) {
	    print $cgi->p, "\n";
	    trailer(0);
	    exit(0);
	}

    # non-CGI parsed args
    #
    # NOTE: The -0 thru -9 are hacks to deal with negative numbers
    #	    on the command line.
    #
    } elsif (!GetOptions(%optctl)) {
	err("usage: $0 $usage");
	exit(1);
    }

    # Print help if that is all that is required
    #
    if ($opt_h) {
	print $help;
	exit(0);
    }

    # -c conflicts with -l and -p
    #
    if ($opt_c && ($opt_l || $opt_p)) {
	if ($html == 0) {
	    err("-c conflicts with either -l and/or -p");
	} else {
	    err("You may only print decimal digits when the <I>Type of " .
	        "input</I>\nis <B>just a number</B>.");
	}
    }

    # determine if dashes will appear in the name
    #
    if ($opt_d) {

	# print -'s between useful parts of the name
	#
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
	# snarf the number from the entire stdin
	#
	$/ = undef;
	$num = <>;
    }

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
	}
    }

    # firewall
    #
    if ($num =~ /\Q$point\E.*\Q$point\E/o) {
	err("Numbers may have only one decimal $point.");
    }
    if ($num =~ /^$/) {
	$num = "0";
    }

    # If scientific (e or E notation), verify format
    # and convert it into a long decimal value.
    #
    if ($num =~ /[eE]/) {
	if ($num !~ /^[\d\Q$point\E]+[Ee]-?\d+$/o) {
	    err(
	        "Scientific numbers may only have a leading -, digits\n" .
		"an optional decimal $point (optionally followed by digits)\n" .
		"before e (or E).  The e (or E) may only be followed by an\n" .
		"optional - and 1 more more digits after the e.  All\n" .
		"3 digit separators, leading 0's and whitespace characters\n" .
		"are ignored.");
	}
	if ($num !~ /^\Q$point\E?\d/o) {
	    err("Scientific numbers must at least a digit before the e.");
	}
	$num = exp_number($num, $point, \$bias);

    # We did not have a number in scientific notation so we have no bias
    #
    } else {
	$bias = Math::BigInt->bzero();
    }

    # verify that we have a valid number
    #
    if ($num !~ /^[\d\Q$point\E]+$/o || $num =~ /^\Q$point\E$/) {
	err("A number may only have a leading -, digits and an " .
	       "optional decimal ``$point''.\n" .
	       "All 3 digit separators and" .
	       "whitespace characters and leading 0's are ignored.");
    }

    # split into integer and fractional parts
    #
    ($integer, $fract) = split /\Q$point\E/, $num;
    if ($integer =~ /^$/) {
	$integer = "0";
    }

    # verify that the number and the bias match
    #
    # We have a non-zero bias when we convert from scientific notation and
    # there is not enough digits right or left of the decimal point/comma.
    # A $bias > 0 can only happen when we have a 0 $fract part.
    # A $bias < 0 can only happen when we have a 0 $integer part.
    #
    if ($bias > 0 && defined($fract) && $fract != 0) {
	err("FATAL: Internal error, bias: $bias > 0 and fract: $fract != 0");
    }
    if ($bias < 0 && defined($integer) && $integer != 0) {
	err("FATAL: Internal error, bias: $bias < 0 and int: $integer != 0");
    }

    # setup to output
    #
    if ($html) {
	print $cgi->p, "\n";
	print $cgi->hr, "\n";
	print $cgi->p, "\n";
	if ($opt_c) {
	    print $cgi->b("Decimal value:"), "\n";
	} else {
	    print $cgi->b("Name of number:"), "\n";
	}
	print $cgi->p, "\n";
	print "<BLOCKQUOTE><PRE>\n";
	$preblock = 1;
    }

    # catch the case where we only want to enter a power of 10
    #
    if ($opt_p || $opt_l) {

       # only allow powers of 10 that are non-negative integers
       #
       if (defined($fract) || $neg) {
	    err("The power must be a non-negative integer.");

       # print the name
       #
       } else {
	   power_of_ten(\$integer, $system, $bias);
       }

    # print the number comma/dot separated
    #
    } elsif ($opt_c) {

	if ($opt_o) {
	    print_number($sep, $neg, \$integer, $point, \$fract, 0, $bias);
	} else {
	    print_number($sep, $neg, \$integer, $point, \$fract, 76, $bias);
	}

    # otherwise print the first part of the response if allowed
    #
    } else {
	print_name($neg, \$integer, \$fract, $system, $bias);
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
#	$point	the decimal point/comma
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

    # we have something like -3.5e70 or .5e50 or 4E50 or 4.E-49
    # break it apart into before and after the E
    #
    ($lead, $expstr) = split(/[Ee]/, $num);
    $exp = Math::BigInt->new($expstr);

    # If we have a 0 exponent, just return the lead with a zero bias
    #
    if ($exp == 0) {
	$$bias = Math::BigInt->bzero();
	return $lead;
    }

    # We need to split the lead between before and after the
    # decimal point/comma
    #
    ($int, $frac) = split(/\Q$point\E/, $lead);
    $frac = "" if !defined($frac);

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
	# only part of the $frac to the $int side
	#
	} else {
	    # we use $expstr because we know that it is a small value
	    $int .= substr($frac, 0, $expstr);
	    $frac = substr($frac, $expstr);
	    $$bias = Math::BigInt->bzero();
	}

    # If we need to move the decimal point/comma to the left, then
    # we do so by moving digits from the end of $int onto the front
    # if $frac and adding more 0's on the front of $frac as needed.
    #
    } elsif ($exp < 0) {

	# If we have more exp than $int digits, then we just
	# tack the $int part onto the front of the $int part
	# and set $int to 0.  This will result in a power of
	# ten bias < 0.
	#
	if (length($int) <= -$exp) {

	    # move all $int digits to the right of decimal point/comma
	    #
	    $$bias = $exp + length($int);
	    $frac = $int . $frac;
	    $int = "0";

	# we have fewer exp than $int digits, so we will move
	# only part of the $int to the $frac side
	#
	} else {
	    # we use $expstr because we know that it is a small value
	    $frac = substr($int, $expstr) . $frac;
	    $int = substr($int, 0, length($int)+$expstr);
	    $$bias = Math::BigInt->bzero();
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
#	$sep		, or . set of 3 digit separators
#	$neg		1 => number is negative, 0 => non-negative
#	\$integer	integer part of the number
#	$point		decimal point/comma
#	\$fract		fractional part of number (or undef)
#	$linelen	max line length (0 => no limit)
#	$bias		power of 10 bias (as BigInt) during de-sci
#			    notation conversion
#
sub print_number($$$$$$$)
{
    # get args
    my ($sep, $neg, $integer, $point, $fract, $linelen, $bias) = @_;
    my $wholelen;	# length of the integer part as modified by bias
    my $intlen;		# length of the integer part without bias
    my $fractlen;	# length of the fractional part
    my $leadlen;	# length of digits, separators and - on 1st line
    my $col;		# current output column, first col is 1
    my $i;

    # deal with the zero special case
    #
    if (!defined($$integer) || $$integer eq "") {
	$$integer = "0";
    }

    # determine if the web limits will apply
    #
    $intlen = 0;
    if (defined($$integer)) {
	$intlen = length($$integer);
    }
    $fractlen = 0;
    if (defined($$fract)) {
	$fractlen = length($$fract);
    }
    if ($html) {
	my $fulllen;	# approximate length of the input as BigInt

	# $fulllen = abs($bias) + $fractlen + int($intlen*4/3)
	$fulllen = $bias->copy();
	$fulllen->babs();
	$fulllen->badd($fractlen);
	$fulllen->badd(int($intlen*4/3));
	# if $fulllen > $big_decimal
	if ($fulllen->bcmp($big_decimal) > 0) {
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
    #
    if ($linelen == 0) {

	# Print the number, and fraction if it exists on a single line.
	#
	if (defined($$fract)) {

	    # deal with a leading - if needed
	    print "-" if $neg;

	    # print thru the decimal point
	    print $$integer, $point;

	    # if biased, print 0's then fract
	    if ($bias < 0) {

		# print 0's in big_bias chuncks at a time
		#
		# NOTE: Some implementations, using a BigInt count
		#	in an x (duplication) does not work.  So we
		#	avoid this by printing big_bias chuncks at a time.
		#
		$bias->badd($big_bias);
		while ($bias < 0) {
		    print "0" x $big_bias;
		    $bias->badd($big_bias);
		}
		$bias->bsub($big_bias);
		if ($bias != 0) {
		    my $tmp;
		    $tmp = $bias->bstr();
		    print "0" x -$tmp;
		}
	    }

	    # print the remainder of the fraction
	    #
	    print $$fract;

	} else {

	    # deal with a leading - if needed
	    print "-" if $neg;

	    # print the integer digits
	    print $$integer;

	    # if biased, print 0's
	    if ($bias > 0) {

		# print 0's in big_bias chuncks at a time
		#
		# NOTE: Some implementations, using a BigInt count
		#	in an x (duplication) does not work.  So we
		#	avoid this by printing big_bias chuncks at a time.
		#
		$bias->bsub($big_bias);
		if ($bias > 0) {
		    print "0" x $big_bias;
		    $bias->bsub($big_bias);
		}
		$bias->badd($big_bias);
		if ($bias != 0) {
		    my $tmp;
		    $tmp = $bias->bstr();
		    print "0" x $tmp;
		}
	    }
	}

    # If we have a line length, we need to insert newlines after
    # the separators to keep within the max line length.
    #
    } else {

	# determine the length of the integer part of the number
	#
	$wholelen = Math::BigInt->new($intlen);
	if ($bias > 0) {
	    $wholelen += $bias;
	}
	$leadlen = $wholelen->copy();
	if ($wholelen->bcmp(3) > 0) {	# if >3
	    my $tmp;

	    # account for separators
	    #
	    # Some BigInt implementations issue uninitialized
	    # warnings internal to the BigInt code with the
	    # division below.  We block these bogus warnings.
	    #
	    # $leadlen += ($wholelen-1)/3;
	    #
	    $tmp = $wholelen->copy();
	    $tmp->bdec();
	    $^W = 0;
	    $tmp->bdiv($three);
	    $^W = $warn;
	    $leadlen->badd($tmp);
	}
	if ($neg) {
	    # account for - sign
	    $leadlen->binc();
	}

	# print enough the leading whitespace so that the
	# decimal point/comma will line up at the end of a line
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# modulus below.  We block these bogus warnings.
	#
	$^W = 0;
	$col = ($linelen - (($leadlen+1) % $linelen)) % $linelen;
	$^W = $warn;
	print " " x $col;

	# process a leading -, if needed
	#
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
		print "-";
	    }
	}

	# output the leading digits before the first separator
	#
	if ($bias > 0) {

	    # Some BigInt implementations issue uninitialized
	    # warnings internal to the BigInt code with the
	    # modulus below.  We block these bogus warnings.
	    #
	    $^W = 0;
	    # avoid turning $i in to a BitInt because of the
	    # later use in substr()
	    if ($bias % 3 == 0) {
		$i = $intlen % 3;
	    } elsif ($bias % 3 == 1) {
		$i = ($intlen+1) % 3;
	    } else {
		$i = ($intlen+2) % 3;
	    }
	    $^W = $warn;
	} else {
	    $i = $intlen % 3;
	}
	if ($i == 0) {
	    $i = 3;
	}
	$col += $i;
	if ($i > $intlen) {
	    print substr($$integer, 0, $i), 0 x ($i-$intlen);
	} else {
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
	    } else {
		print $sep;
	    }

	    # output 3 more digits
	    #
	    if ($i+3 > $intlen) {
		print substr($$integer, $i, 3), 0 x ($i+3-$intlen);
	    } else {
		print substr($$integer, $i, 3);
	    }
	    $col += 3;
	    $i += 3;
	}

	# if biased > 0, output sets of 0's until decimal point/comma
	#
	if ($wholelen->bcmp($intlen) > 0)  {	# if >$intlen
	    while ($wholelen->bcmp($i) > 0) {	# while $i < $wholelen

		# output the separator, we add a newline if the line
		# is at or beyond the limit
		#
		if (++$col >= $linelen) {
		    print "$sep\n";
		    $col = 1;
		} else {
		    print $sep;
		}

		# output 3 more digits
		#
		print "000";
		$col += 3;
		$i += 3;
	    }
	}

	# print the decimal point/comma followed by the fractional
	# part if needed
	#
	if (defined($$fract)) {
	    my $offset;		# offset within fract bring printed

	    # print the decimal point/comma and move to a new line
	    #
	    print "$point\n";
	    $col = 1;
	    $offset = 0;

	    # if biased, print leading 0's then the fract digits
	    # line with the first fract digits
	    #
	    if ($bias < 0) {

		# print whole lines of 0's while we have lots of bias
		#
		# while $bias < -$linelen
		$bias->badd($linelen);
		while ($bias < 0) {
		    print "0" x $linelen, "\n";
		    $bias->badd($linelen);
		}
		$bias->bsub($linelen);

		# print the last line of bias 0's
		#
		# NOTE: Some implementations, using a BigInt count
		#	in an x (duplication) does not work.  So we
		#	avoid this by printing using a scalar repeater.
		#
		if ($bias != 0) {
		    $i = $bias->bstr();
		    print "0" x -$i;
		    $offset += -$i;
		}

		# print the first line of fract to fill out the line
		#
		if ($offset <= $linelen) {
		    print substr($$fract, 0, $linelen-$offset), "\n";
		} else {
		    print "\n";
		}

		# print the rest of the faction in linelen chunks
		#
		for ($i = $linelen-$offset; $i < $fractlen; $i += $linelen) {
		    print substr($$fract, $i, $linelen), "\n";
		}

	    # non-biased printing of fract digits
	    #
	    } else {

		# print the rest of the faction in linelen chunks
		#
		for ($i = 0; $i < $fractlen; $i += $linelen) {
		    print substr($$fract, $i, $linelen), "\n";
		}
	    }
	}
    }

    # end of the number
    print "\n";
}


# latin_root - return the Latin root of a number
#
# given:
#	$num	   number to construct
#	$millia	   addition number of millia to add to the latin_root
#
# Prints the latin root name on which we can add llion or lliard to
# form a name for 1000^($num+1), depending on American or European
# name system.
#
# The effect of $millia is to multiply $num by 1000^$millia.
#
sub latin_root($$)
{
    my ($num, $millia) = @_;	# get args
    my $numstr;	# $num as a string
    my @set3;	# set of 3 digits, $set3[0] is the most significant
    my $d3;	# 3rd digit in a set of 3
    my $d2;	# 2nd digit in a set of 3
    my $d1;	# 1st digit in a set of 3
    my $l3;	# latin name for 3rd digit in a set of 3
    my $l2;	# latin name for 2nd digit in a set of 3
    my $l1;	# latin name for 1st digit in a set of 3
    my $len;	# number of sets of 3 including the final (perhaps partial) 3
    my $millia_cnt;		# number of millia's to print
    my $i;

    # firewall
    #
    if ($millia < 0) {
	err("FATAL: Internal error, millia: $millia < 0 in latin_root()");
    }

    # deal with small special cases for small values
    #
    if ($millia == 0 && $num < @l_special) {
	print $l_special[$num], $dash;
	return;
    }

    # determine the number of sets of 3 and the length
    #
    ($numstr = $num) =~ s/[^\d]//g;
    $i = length($numstr);
    $len = int(($i + 2) / 3);
    if ($i % 3 == 0) {
	@set3 = unpack("a3"x$len, $numstr);
    } elsif ($i % 3 == 1) {
	@set3 = unpack("a"."a3"x($len-1), $numstr);
	$set3[0] = "00" . $set3[0];
    } else {
	@set3 = unpack("a2"."a3"x($len-1), $numstr);
	$set3[0] = "0" . $set3[0];
    }

    # Determine how many millia's we will initially print
    #
    # We have to be careful about how we compute $millia+len-1
    # so that it will not become a floating value.
    #
    $millia_cnt = $millia->copy();
    $millia_cnt->badd($len);

    # process each set of 3 digits up to but not
    # including the last set of 3
    #
    for ($i=0; $i < $len; ++$i) {

	# keep track of the number of millia's we might print
	#
	if ($millia_cnt > 0) {
	    $millia_cnt->bdec();
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
	$d2 = substr($set3[$i], 1, 1);
	$l2 = (($d2 > 0) ? $l_ten[$d2] . $dash : "");
	$d3 = substr($set3[$i], 0, 1);
	$l3 = (($d3 > 0) ? $l_hundred[$d3] .
			   (($i == $len-1 && $d1 == 0 && $d2 == 0) ? "" : "t") .
			   $dash : "");

	# print the 3 digits
	#
	# We will skip the printing of the 3 digits if
	# we have just 001 in all but the lowest set of 3.
	# This results in no output so that we wind up with
	# something such as:
	#
	#	something-tillion
	#
	# instead of:
	#
	#	un-something-tillion
	#
	if ($i > 0 || $d3 != 0 || $d2 != 0 || $d1 != 1) {
	    print "$l3$l1$l2";
	}

	# print millia's as needed
	#
	if ($millia > 0 || $i < $len-1) {
	    if ($opt_m) {

		# print millia's with ^number (-m) notation
		#
		if ($millia_cnt->bcmp(1) > 0) {		# if $millia_cnt > 1
		    print "millia^", $millia_cnt->bstr(), $dash;
		} else {
		    print "millia", $dash;
		}
	    } else {

		# print the millia's without ^number (-n) notation
		#
		# NOTE: Some implementations, using a BigInt count
		#	in an x (duplication) does not work.  So we
		#	avoid this by printing big_bias chuncks at a time.
		#
		$millia_cnt->bsub($big_bias);
		while($millia_cnt > 0) {
		    print "millia$dash" x $big_bias;
		    $millia_cnt->bsub($big_bias);
		}
		$millia_cnt->badd($big_bias);
		if ($millia_cnt != 0) {
		    my $tmp;
		    $tmp = $millia_cnt->bstr();
		    print "millia$dash" x $tmp;
		}

	    }
	}
    }

    # For the case of ending in 1x we need to end in an 'i'
    # instead of the usual 'ti'.  This is because we say:
    #
    #	trecen-dec-illion
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
}


# american_kilo - return the name of power of 1000 under American system
#
# given:
#	$power	power of 1000
#
# Prints the name of 1000^$power.
#
sub american_kilo($)
{
    my $power = $_[0];	# get arg
    my $big;		# $power as a BigInt

    # firewall
    #
    if ($power < 0) {
	err("Negative powers of 1000 not supported: $power");
    }

    # We treat 0 as nothing
    #
    if ($power == 0) {
	return;

    # We must deal with 1 special since it does not use a direct Latin root
    #
    } elsif ($power == 1) {
	print "thousand";

    # Otherwise we use the Latin root process to construct the value.
    #
    } else {
	$big = Math::BigInt->new($power);
	latin_root($big->bdec(), Math::BigInt->bzero());
	print "llion";
    }
}


# european_kilo - return the name of power of 1000 under European system
#
# given:
#	$power	power of 1000
#
# Prints the name of 1000^$power.
#
# The European system uses both "llion" and "lliard" suffixes for
# each root value.  The "llion" is for even powers and the "lliard"
# is for off powers.
#
# Because both "llion" and "lliard" suffixes are used, we need to
# divide in half, the value before using the Latin root system.
#
sub european_kilo($)
{
    my $power = $_[0];		# get arg
    my $mod2;			# $power mod 2
    my $big;			# $power as a BigInt

    # firewall
    #
    if ($power < 0) {
	err("Negative powers of 1000 not supported: $power");
    }

    # We treat 0 as nothing
    #
    if ($power == 0) {
	return;

    # We must deal with 1 special since it does not use a direct Latin root
    #
    } elsif ($power == 1) {
	print "thousand";

    # Use latin_root to determine the root while taking care to
    # deterine of we will end in "llion" (even big,biasmillia combo)
    # or end in "lliard" (odd big,biasmillia combo).
    #
    } else {

	# divide $power by 2 and note if it was even or odd
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# bdiv below.  We block these bogus warnings.
	#
	$big = Math::BigInt->new($power);
	$^W = 0;
	($big, $mod2) = $big->bdiv($two);
	$^W = $warn;

	# Even roots use "llion"
	#
	if ($mod2 == 0) {
	    latin_root($big, Math::BigInt->bzero());
	    print "llion";

	# Odd roots use "lliard"
	#
	} else {
	    latin_root($big, Math::BigInt->bzero());
	    print "lliard";
	}
    }
}


# power_of_ten - just print name of a the power of 10
#
# given:
#	\$power	the power of 10 to name print
#	$system	the number system ('American' or 'European')
#	$bias	power of 10 bias (as BigInt) during de-sci notation conversion
#
sub power_of_ten($$$)
{
    my ($power, $system, $bias) = @_;	# get args
    my $kilo_power;			# power of 1000 to ask about
    my $big;				# $power as a BigInt
    my $mod3;				# $big mod 3
    my $mod2;				# $kilo_power mod 2
    my $biasmod3;			# bias mod 3
    my $biasmillia;			# int(bias/3)
    my $bias_big;			# approx power of 10 ($bias+$big)
    my $i;

    # firewall
    #
    if ($bias < 0) {
	err("FATAL: Internal error, bias: $bias < 0 in power_of_ten()");
    }

    # Convert $$power arg into BigInt format
    #
    $big = Math::BigInt->new($$power);

    # convert the power of 10 into a multiplier and a power of 1000
    #
    # If we gave -l, then we will assume that we are dealing with
    # a power of 1000 instead of a power of 10.
    #
    if ($opt_l) {

	# Web firewall
	#
	if ($html && !$opt_m && $bias->bcmp($big_latin_power) > 0) {
	    big_err();
	}

	# increase the power based on bias mod 3
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# division and mod below.  We block these bogus warnings.
	#
	$^W = 0;
	($biasmillia, $biasmod3) = $bias->bdiv($three);
	$^W = $warn;
	if ($biasmod3 == 1) {
	    $big->bmul($ten);
	} elsif ($biasmod3 == 2) {
	    $big->bmul($hundred);
	}

	# under -l, we deal with powers of 1000 above 1000
	#
	$kilo_power = $big->copy();

	# under -l, our multiplier name is always one
	#
	print "one";

    } else {

	# firewall
	#
	if ($bias != 0) {
	    if ($html) {
		err("Scientific notation is not supported for powers\n" .
		  "of 10 at this time. Try using <B>Latin powers</B> or enter" .
		  " the\nnumber without scientific notation.");
	    } else {
		err("Scientific notation is not supported for powers of" .
		       "10\n" .
		       "of 10 at this time.  Try using Latin powers or enter" .
		       " the\nnumber without scientific notation.");
	    }
	}

	# convert power of 10 into power of 1000
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# bdiv below.  We block these bogus warnings.
	#
	$^W = 0;
	($kilo_power, $mod3) = $big->bdiv(3);
	$^W = $warn;
	$biasmillia = Math::BigInt->bzero();

	# print the multiplier name
	#
	if ($mod3 < 1) {
	    print "one";
	} elsif ($mod3 == 1) {
	    print "ten";
	} else {
	    print "one hundred";
	}
    }

    # A zero kilo_power means that we only have 1, 10 or 100
    # and so there is nothing else to print.
    #
    if ($kilo_power->bcmp(1) < 0 && $biasmillia == 0) {
	# nothing else to print

    # We must treat a kilo_power of 1 as a special case
    # because 'thousand' does not have a Latin root base.
    #
    } elsif ($kilo_power == 1 && $biasmillia == 0) {
	print " thousand";

    # print the name based on the American name system
    #
    } elsif ($system eq 'American') {

	print " ";
	latin_root($kilo_power->bdec(), $biasmillia);
	print "llion";

    # print the name based on the European name system
    #
    } else {

	# divide $kilo_power by 2 taking into account any $biasmillia
	#
	# We must determine if the kilo_power and biasmillia combination
	# is even or odd.
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# division and mod below.  We block these bogus warnings.
	#
	$^W = 0;
	if (($kilo_power % 2) == 0) {

	    # kilo_power is even so kilo_power,biasmillia is even
	    #
	    $kilo_power->bdiv($two);
	    $mod2 = 0;

	} else {

	    # If we have biasmillia, then the kilo_power,biasmillia combination
	    # is even.  We divide by 2 by multiplying by 500 while reducing
	    # biasmillia by one.  This results in an even number.
	    #
	    if ($biasmillia > 0) {
		$kilo_power->bmul($five_hundred);
		$biasmillia->bdec();
		$mod2 = 0;

	    # We do not have biasmillia and kilo_power is odd, so we must use
	    # the "lliard" roots
	    #
	    } else {
		$kilo_power->bdec();
		$kilo_power->bdiv($two);
		$mod2 = 1;
	    }
	}
	$^W = $warn;

	# Even roots use "llion"
	#
	if ($mod2 == 0) {
	    print " ";
	    latin_root($kilo_power, $biasmillia);
	    print "llion";

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


# print_name - print the name of a number
#
# given:
#	$neg		1 => number is negative, 0 => non-negative
#	\$integer	integer part of the number
#	\$fract		fractional part of number (or undef)
#	$system		number system ('American' or 'European')
#	$bias		power of 10 bias (as BigInt) during de-sci
#			    notation conversion
#
sub print_name($$$$$)
{
    my ($neg, $integer, $fract, $system, $bias) = @_;	# get args
    my $bias_mod3;	# bias % 3
    my $millia;		# millia arg, power of 1000 for a given set f 3
    my $intstr;		# integer as a string
    my $intlen;		# length of integer part in digits
    my $fractlen = 0;	# length of the fractional part
    my $cnt3;		# current set of 3 index (or partial of highest)
    my $set3;		# set of 3 digits
    my $indx;		# index into integer
    my $i;

    # process a leading -, if needed
    #
    if ($neg) {
	print "negative ";
    }

    # must deal with the zero as a special case
    #
    if ($$integer eq "0") {
	print "zero";
    }

    # convert integer to string
    #
    ($intstr = $$integer) =~ s/[^\d]//g;

    # For a bias > 0, we want that bias to be a multiple of 3
    # so that we can add it to the 1st arg (power of 1000) of
    # either american_kilo() or european_kilo().
    #
    # We any bias % 3 and 'move' to the integer by adding 1 or 2 0's
    # to the end of it.
    #
    if ($bias > 0) {

	# compute $bias % 3 and make $bias a multiple of 3
	#
	# Some BigInt implementations issue uninitialized
	# warnings internal to the BigInt code with the
	# bdiv below.  We block these bogus warnings.
	#
	$^W = 0;
	($bias, $bias_mod3) = $bias->bdiv($three);
	$^W = $warn;

	# ``move`` the $bias % 3 value onto the end of integer
	#
	if ($bias_mod3 == 1) {
	    $intstr .= "0";
	} elsif ($bias_mod3 == 2) {
	    $intstr .= "00";
	}
    }

    # determine the number of sets of 3
    #
    $intlen = length($intstr);
    $cnt3 = int(($intlen+2)/3);
    $millia = Math::BigInt->new($bias);

    # determine if the web limits will apply
    #
    if (defined($$fract)) {
	$fractlen = length($$fract);
    }
    if ($html) {
	my $fulllen;	# approximate length of the input as BigInt

	$fulllen = Math::BigInt->new(abs($fractlen) + abs($intlen));
	if ($bias < 0) {
	    $fulllen->bsub($bias);
	}
	if ($fulllen->bcmp($big_digits) > 0) {	# if $fulllen > $big_digits
	    big_err();
	}
    }

    # print the highest order set, which may be partial
    #
    $indx = 3-((3*$cnt3)-$intlen);
    $set3 = substr($intstr, 0, $indx);
    print_3($set3);
    print " ";
    --$cnt3;
    if ($system eq 'American') {
	if ($bias > 0) {
	    american_kilo($millia+$cnt3);
	} else {
	    american_kilo($cnt3);
	}
    } else {
	if ($bias > 0) {
	    european_kilo($millia+$cnt3);
	} else {
	    european_kilo($cnt3);
	}
    }

    # process all of the the remaining full sets of 3 (if any)
    #
    while (--$cnt3 >= 0) {
	$set3 = substr($intstr, $indx, 3);
	$indx += 3;
	next if $set3 == 0;
	if ($opt_o) {
	    print ", ";
	} else {
	    print ",\n";
	}
	print_3($set3);
	if ($cnt3 > 0 || $bias > 0) {
	    print " ";
	    if ($system eq 'American') {
		if ($bias > 0) {
		    american_kilo($millia+$cnt3);
		} else {
		    american_kilo($cnt3);
		}
	    } else {
		if ($bias > 0) {
		    european_kilo($millia+$cnt3);
		} else {
		    european_kilo($cnt3);
		}
	    }
	}
    }

    # print after the decimal point if needed
    #
    if (defined($$fract)) {
        my $len;	# length of current line
	my $line;	# current line being formed

	# mark the decimal point/comma
	#
	if (!$opt_o) {
	    print "\n";
	}
	if ($system eq 'American') {
	    print "point";
	} else {
	    print "comma";
	}
	if ($opt_o) {
	    print " ";
	} else {
	    print "\n";
	    $len = 0;
	}

	# if biased, print off leading zero's
	#
	while ($bias < 0) {
	    my $zero = $digits[0];		# zero digit
	    my $diglen = length($zero)+1;	# length of zero name + space

	    $bias->binc();
	    if ($opt_o) {
		print " $zero";
	    } else {
		if ($len <= 0) {
		    print $zero;
		    $len = $diglen - 1;
		} elsif ($len + $diglen < 80) {
		    print " $zero";
		    $len += $diglen;
		} else {
		    print "\n$zero";
		    $len = $diglen - 1;
		}
	    }
	}

	# list off the digits
	#
	for ($i=0; $i < length($$fract); ++$i) {
	    my $dig = $digits[substr($$fract, $i, 1)];	# the digit to print
	    my $diglen = length($dig)+1;		# length of digit + ' '

	    if ($opt_o) {
		print " $dig";
	    } else {
		if ($len <= 0) {
		    print $dig;
		    $len = $diglen - 1;
		} elsif ($len + $diglen < 80) {
		    print " $dig";
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

    # pre-compute name of 3 digits if we do not alread have it
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
	    $name_3 = $digits[$number/100] . " hundred";
	}

	# determine the name of tens and one if more than 19
	#
	$num = $number % 100;
	if ($num > 19) {
	    if ($number > 99) {
		$name_3 .= " ";
	    }
	    $name_3 .= $tens[$num/10];
	    if ($num % 10 > 0) {
		$name_3 .= " " . $digits[$num % 10];
	    }

	# determine the name of tens and one if more than 9
	#
	} elsif ($num > 9) {
	    if ($number > 99) {
		$name_3 .= " ";
	    }
	    $name_3 .= $teens[$num-10];

	# otherwise determine the name the digit
	#
	} elsif ($num > 0) {
	    if ($number > 99) {
		$name_3 .= " ";
	    }
	    $name_3 .= $digits[$num];
	}

	# save the 3 digit name
	#
	$english_3[$number] = $name_3;
    }

    # print the 3 digit name
    #
    print $english_3[$number];
}


# cgi_form - print the CGI/HTML form
#
# returns:
#	$num	input value
#
sub cgi_form()
{
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
    );
    my %dash_label = (
	"nodash" => " without any -'s",
	"dash" => " with -'s between parts of words"
    );

    print $cgi->header, "\n";
    print $cgi->start_html(
	  -title => 'The English name of a number',
	  -bgcolor => '#98B8D8'), "\n";
    print $cgi->h1('The English name of a number'), "\n";
    print $cgi->p, "\n";
    print "See the ", "\n";
    print $cgi->a({'HREF' =>
	  	  "http://www.isthe.com/chongo/tech/math/number/example.html"},
		  "example / help");
    print " page for an explanation of the options below.\n";
    print $cgi->br, "\n";
    print "See also the ", "\n";
    print $cgi->a({'HREF' =>
	  	   "http://www.isthe.com/chongo/tech/math/number/number.html"},
		  "English name of a number home page"), "\n";
    print ".\n";
    print $cgi->p, "\n";
    print $cgi->start_form, "\n";
    print "Type of input:", "\n";
    print "&nbsp;" x 4, "\n";
    print $cgi->radio_group(-name => 'input',
			  -values => ['number', 'exp', 'latin'],
			  -labels => \%input_label,
			  -default => 'number'), "\n";
    print $cgi->br, "\n";
    print "Type of output:", "\n";
    print "&nbsp;" x 2, "\n";
    print $cgi->radio_group(-name => 'output',
			  -values => ['name', 'digit'],
			  -labels => \%output_label,
			  -default => 'name'), "\n";
    print $cgi->br, "\n";
    print "Name system:", "\n";
    print "&nbsp;" x 4, "\n";
    print $cgi->radio_group(-name => 'system',
			  -values => ['usa', 'europe'],
			  -labels => \%system_label,
			  -default => 'usa'), "\n";
    print $cgi->br, "\n";
    print "Millia style:", "\n";
    print "&nbsp;" x 8, "\n";
    print $cgi->radio_group(-name => 'millia',
			  -values => ['dup', 'power'],
			  -labels => \%millia_label,
			  -default => 'dup'), "\n";
    print $cgi->br, "\n";
    print "Dash style:", "\n";
    print "&nbsp;" x 10, "\n";
    print $cgi->radio_group(-name => 'dash',
			  -values => ['nodash', 'dash'],
			  -labels => \%dash_label,
			  -default => 'nodash'), "\n";
    print $cgi->p, "\n";
    print $cgi->b('<FONT SIZE="+1">Enter a number:</FONT>'), "\n";
    print $cgi->br, "\n";
    print $cgi->textarea(-name => 'number',
		         -rows => '10',
		         -columns => '60'), "\n";
    print $cgi->p, "\n";
    print $cgi->submit(name=>'Name that number'), "\n";
    print "&nbsp;NOTE: We limit POSTs on web to ~$big_input characters,\n";
    print "see below.\n";
    print $cgi->end_form, "\n";

    # Prep for the reply
    #
    # We need to convert the CGI parameters into values that
    # would have been set if we were processing the input
    # on the command line.
    #
    # determine the input mode
    #
    if (defined($cgi->param('input'))) {
	if ($cgi->param('input') eq "exp") {
	    $opt_p = 1;	# assume -p (power of 10)
	} elsif ($cgi->param('input') eq "latin") {
	    $opt_l = 1;	# assume -l (1000 ^ number))
	}
    }

    # determine the output mode
    #
    if (defined($cgi->param('output')) &&
	$cgi->param('output') eq "digit") {
	$opt_c = 1;		# assume -c (comma/dot decimal)
    }

    # determine the system
    #
    if (defined($cgi->param('system')) &&
	$cgi->param('system') eq "europe") {
	$opt_e = 1;		# assume -e (European system)
    }

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

    # return the number
    #
    return $cgi->param('number');
}

# trailer - print the trailer
#
# given:
#	$arg	1 => suppress message about obtaining the source
#
# If the arg passed is 1, then the message about obtaining the source
# if suppressed.
#
sub trailer($)
{
    my $arg = $_[0];

    # close off input
    #
    if ($preblock && $html == 1) {
	print $cgi->p, "\n";
	print "</PRE>\n</BLOCKQUOTE>\n";
    }

    # section off with a line
    #
    if ($html == 1) {
	print "<HR>\n<P>\n";
    }

    # display how to get to the source
    #
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
    }

    print <<END_OF_HTML;
    <P>
    Brought to you by:
    </P> <BLOCKQUOTE>
    Landon Curt Noll
    <BR>
    <A HREF="http://www.isthe.com/chongo/index.html">chongo</A>
    &lt; was here &gt;
    <STRONG>/\\oo/\\</STRONG>
    </BLOCKQUOTE>

    </BODY>
    </HTML>
END_OF_HTML
}


# big_err - print a too big error and exit
#
sub big_err()
{

    # close off input
    #
    if ($preblock) {
	print $cgi->p, "\n";
	print "</PRE>\n</BLOCKQUOTE>\n";
    }

    # print too big error
    #
    print $cgi->p,
	  $cgi->b("SORRY!"),
	  "&nbsp;&nbsp;We have imposed an arbitrary size limit on",
	  " the output of this CGI program.",
	  $cgi->p,
	  "Even though there is no limit on the size of\n",
	  "of number that the algorithm can name, we had to put some limit\n",
	  "on the amount of output we will print.  Otherwise someone\n",
	  "could enter a huge number such as causing the server to flood the\n",
	  "network with lots of data ... assuming we had the memory to form\n",
	  "the print buffer in the first place!\n";

    # tell about some of the limits
    #
    print $cgi->p,
	  "The arbitrary size limit as approximately as follows:\n",
	  "<UL>\n",
	  "<LI> No more than $big_input characters of input\n",
	  "<LI> Latin power scientific notation exponent &lt; ",
		$big_latin_power, " when using non-compact millia style<BR>\n",
	        "(i.e., when entering <I>digits</I><B>e</B><I>exp</I> ",
		"keep <I>exp</I> &lt; ", $big_latin_power,
		" or use compact <I>millia^7...</I> Millia style)\n",
	  "<LI> Decimal expansion limited to about $big_decimal digits\n",
	  "</UL>\n";

    # print a suggestion
    #
    if ($opt_c) {
	print $cgi->p,
	      "Instead of printing the digits of a number, you might\n",
	      "try printing the ",
	      $cgi->b("English name"),
	      " instead.\n";
    } elsif ($opt_p) {
	print $cgi->p,
	      "You might try rasing ",
	      $cgi->b("Latin powers"),
	      " (1000^latin_power) instead of just powers of 10.\n";
    } elsif ($opt_l && !$opt_m) {
	print $cgi->p,
	      "You might try turning on the\n",
	      $cgi->b("compact form"),
	      " of the Millia style (e.g., millia^7).\n",
	      "Often that reduces the amount of output enough\n",
	      "to drop under the arbitrary size limit.\n";
    }

    # tell them about running it themselves
    #
    print $cgi->p,
	  "If none of those options are what you want/need, you can\n",
	  "run this program on your own computer in the non-CGI mode.\n",
	  "The non-CGI mode has no internal size restrictions and is\n",
	  "limited only by time and your systems resources.\n",
	  "You may download the\n",
	  $cgi->a({'href' => "/chongo/tech/math/number/number"},
		  "source"),
	  " and run it yourself.\n",
	  $cgi->p,
	  "If you do download the\n",
	  $cgi->a({'href' => "/chongo/tech/math/number/number"},
		  "source"),
	  " save it as either the filename ",
	  $cgi->b("number.cgi"),
	  " or ",
	  $cgi->b("number"),
	  ".",
	  " The CGI script ",
	  $cgi->b("number.cgi"),
	  " operates as it is doing now with size limits.",
	  " The Perl script ",
	  $cgi->b("number"),
	  " reads a number from standard input, has no size limits",
	  "and does not perform any CGI/HTML actions.",
	  "</ol>\n",
	  $cgi->p;
    trailer(1);
    exit(1);
}


# err - report an error in CGI/HTML or die form
#
# given:
#	$msg	the message to print
#
sub err($)
{
    my $msg = $_[0];	# get args

    # just issue the die message if not in CGI/HTML mode
    #
    if ($html == 0 || $cgi == 0) {
	if ($html != 0) {
	    print "Content-type: text/plain\n\n";
	}
	die $msg, "\n";
    }

    # issue an error message in CGI/HTML
    #
    if ($preblock == 0) {
	print $cgi->p, "\n";
	print $cgi->hr, "\n";
	print $cgi->p, "\n";
    }
    print $cgi->b("SORRY!"), "\n", $msg, "\n";
    trailer(0);
    exit(1);
}
