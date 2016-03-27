Contents:

    number      A command line tool
    number.cgi  A CGI script (identical to number except in filename)
    number.tgz  A gzipped tar file of  number, number.cgi and this README

When number is run without a .cgi filename extension, it runs as a
command line tool taking a value from an argumment or from input:

    ./number -p -d 1234567
    echo "12345678901234567890" | ./number -l -r euro

For help try:

    ./number -h

When number is run with a .cgi filename extension, it runs as this CGI script:

    http://www.isthe.com/cgibin/number.cgi

The CGI script limits post to ~2048 characters. The command line
interface does not have this size limitation.

For more information see:

    http://www.isthe.com/number.html
    http://www.isthe.com/chongo/tech/math/number/example.html

NOTE: The cgi script uses the perl CGI.pm module.  While it is
      no longer part of the perl core, it still can installed
      via the command:

	cpanm CGI

      For info on cpanm see:

      	http://search.cpan.org/perldoc?cpanm

    NOTE: RHEL (and systems that use yum) users may install cpanm via:

 	yum install perl-App-cpanminus

####
# HELP WANTED:
#
# This code uses the CGI.pm perl module, which is no longer actively
# maintained.  If you want to help convert this code away from using
# the CGI.pm perl module and instead using a CGI-like module that is
# actucally maintained AND is part of core perl, please convert this
# code and send it to:
#
# 	number-mail at asthe dot com
#
####
