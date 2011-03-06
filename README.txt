For historical reasons, these two files are identical:

    number.cgi		A CGI script
    number		A Perl script

One may also download number.tgz file, which is a gzipped tarball
containing both files and this README.txt file.

=-=

When number is run without a .cgi filename extension, it runs as
a command line.  For example:

    ./number -p -d 1234567
    echo "12345678901234567890" | ./number -l -r euro

For a command line summary, try:

    ./number -h

=-=

When number is run with a .cgi filename extension, it runs as this
CGI script:

    http://www.isthe.com/cgi-bin/number.cgi

The CGI script limits post to ~2048 characters. The command line
interface does not have this size limitation.

=-=

For more information see:

    http://www.isthe.com/number.html
    http://www.isthe.com/chongo/tech/math/number/example.html
