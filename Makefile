#!/bin/make
#  @(#} $Revision: 1.9 $
#  @(#} RCS control in //prime.corp/usr/local/src/cmd/number/Makefile
#
# number - number makefile

SHELL=/bin/sh
MODE=0555
DESTDIR=/usr/local/bin
WWW=/usr/local/ns-home/docs/chongo/number
SCRIPTS= number.cgi.txt number.cgi

all: ${SCRIPTS}

number.cgi.txt: number.pl
	rm -f number.cgi.txt
	cp number.pl number.cgi.txt
	chmod 0555 number.cgi.txt

number.cgi: number.pl
	rm -f number.cgi
	cp number.pl number.cgi
	chmod 0555 number.cgi

# NOTE: The cgi-bin/Makefile forms a symlink between the file:
#
#	${DOC_ROOT}/cgi-bin/nummber.cgi
#
# and our installation file:
#
#	${DESTDIR}/number.cgi
#
# So thus we do NOT need to install number.pl into the cgi-bin directory.
#
install: all
	install -F ${WWW} -u chongo -g user -m 0644 number.cgi.txt
	install -F ${WWW} -u chongo -g user -m 0755 number.cgi
	install -F ${DESTDIR} -m ${MODE} ${SCRIPTS}

clean:

clobber: clean
	rm -f number.cgi.txt number.cgi
