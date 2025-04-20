# number

Print the English Name of a Number of any size.


# To install

```
make clobber all
sudo install clobber
```


# Examples

Make all of the clones of number:

When number is run without a .cgi filename extension, it runs as a
command line tool taking a value from an argumment or from input:

```
$ /usr/local/bin/number -p -d 1234567

$ echo "12345678901234567890" | /usr/local/bin/number -l -r euro
```

When number is run with a .cgi filename extension, it runs as this CGI script.


## Number demo

The number demo (run as a CGI script) may be run from: [http://www.isthe.com/cgi-bin/chongo/number.cgi](http://www.isthe.com/cgi-bin/chongo/number.cgi)

**NOTE**: The CGI script limits post to ~20480 characters. The
command line interface does not have this size limitation.


## Official GitHub repo

The GitHub repo for number is: [https://github.com/lcn2/number](https://github.com/lcn2/number)

For more information see: [http://www.isthe.com/chongo/tech/math/number/number.html](http://www.isthe.com/chongo/tech/math/number/number.html)

as well as: [http://www.isthe.com/chongo/tech/math/number/example.html](http://www.isthe.com/chongo/tech/math/number/example.html)

## IMPORTANT NOTE ABOUT CGI

If you see an error of the form:

> Can't locate CGI.pm in @INC (you may need to install the CGI module) (@INC contains: ...) at /usr/local/bin/number line 278.

You need to install the Perl CGI module.

The cgi script uses the perl CGI.pm module.  While it is no longer part of the perl core, it still can installed via the command:

```
$ cpanm CGI
```

For info on cpanm see: [http://search.cpan.org/perldoc?cpanm](http://search.cpan.org/perldoc?cpanm)

NOTE: RHEL (and systems that use yum) users may install cpanm via:

```
$ dnf install perl-App-cpanminus
```


To use:

```
/usr/local/bin/number [-p] [-l] [-d] [-m] [-c] [-o] [-i] [-r ruleset | -e] [-h] [[--] number]

	-p	input is a power of 10
	-l	input is a Latin power (1000^x)
	-d	add dashes to help with pronunciation
	-m	output name in a more compact exponentiation form
	-c	output number in comma/dot form
	-o	output number on a single line
	-i	Use informal Latin powers (default: use formal)
		Use dodec over duodec and ducen over duocen

	-r ruleset	Output using ruleset: (conflicts with -e)

	    -r american   Output using the American ruleset (default)
	    -r us	  Short for -r american
	    -r european   Output using the European ruleset
	    -r euro	  Short for -r european

	    NOTE: ruleset names are case independent

	-e	Short for -r european (conflicts with -r ruleset)

	-h	print a help message only

	--	the arg that follows is a number (useful if number is <0)

    If number is not given on the command line it is read from standard
    input.

    All whitespace (including newlines), commas and periods
    are ignored, with the exception of a single (optional)
    decimal point (or decimal comma if european name system),
    which if found will be processed.  In the case of reading from
    standard input, all valid data found on standard input will be
    considered as if it were a single number.

    A number may be either in decimal or in scientific notation (e.g.,
    2.5e100).  Negative and floating point numbers are allowed.
    Be careful when using negative on the command line.  One must give
    an -- argument so as to not confuse command parsing.  E.g.:

	./number -- -123

    Updates from time to time are made to this program.  See:

	https://github.com/lcn2/number

    for the latest version of this code.  See also:

	http://www.isthe.com/chongo/tech/math/number/howhigh.html

    You are using Version:

        3.10.4 2024-06-11
```


## HELP WANTED:

This code uses the CGI.pm perl module, which is no longer actively
maintained.  If you want to help convert this code away from using
the CGI.pm perl module and instead using a CGI-like module that is
actively maintained AND is part of core perl, please submit a pull
request with such a change.


# Reporting Security Issues

To report a security issue, please visit "[Reporting Security Issues](https://github.com/lcn2/number/security/policy)".
