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
