# number


## Print the English Name of a Number of any size

Make all of the clones of number:

```
    make all
```

When number is run without a .cgi filename extension, it runs as a
command line tool taking a value from an argumment or from input:

```
    ./number -p -d 1234567
    echo "12345678901234567890" | ./number -l -r euro
```

For help try:

```
    ./number -h
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

```
    Can't locate CGI.pm in @INC (you may need to install the CGI module) (@INC contains: ...) at /usr/local/bin/number line 278.
```

You need to install the Perl CGI module.

The cgi script uses the perl CGI.pm module.  While it is no longer part of the perl core, it still can installed via the command:

```
    cpanm CGI
```

For info on cpanm see: [http://search.cpan.org/perldoc?cpanm](http://search.cpan.org/perldoc?cpanm)

NOTE: RHEL (and systems that use yum) users may install cpanm via:

```
    dnf install perl-App-cpanminus
```


## HELP WANTED:

This code uses the CGI.pm perl module, which is no longer actively
maintained.  If you want to help convert this code away from using
the CGI.pm perl module and instead using a CGI-like module that is
actively maintained AND is part of core perl, please submit a pull
request with such a change.


# Reporting Security Issues

To report a security issue, please visit "[Reporting Security Issues](https://github.com/lcn2/number/security/policy)".
