#!/bin/make
#  @(#} $Revision: 1.1 $
#  @(#} RCS control in //prime.corp/usr/local/src/cmd/number/Makefile
#
# number - number makefile

SHELL=/bin/sh
MODE=0555
DESTDIR=/usr/local/bin
WWW=/usr/local/ns-home/docs/chongo/number
SCRIPTS= number

all: ${SCRIPTS}

number: number.pl
	rm -f number
	cp number.pl number
	chmod 0555 number

install: all
	install -F ${DESTDIR} -m ${MODE} ${SCRIPTS}
	install -F ${WWW} -m 0755 number.pl

clean:

clobber: clean
	rm -f number
