#!/usr/bin/make
#
# number - number makefile
#
# @(#) $Revision: 1.16 $
# @(#) $Id: Makefile,v 1.16 1999/10/11 13:17:41 chongo Exp chongo $
# @(#) $Source: /usr/local/src/cmd/number/RCS/Makefile,v $
#
# Copyright (c) 1999 by Landon Curt Noll.  All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright, this permission notice and text
# this comment, and the disclaimer below appear in all of the following:
#
#       supporting documentation
#       source copies
#       source works derived from this source
#       binaries derived from this source or from derived source
#
# LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
# EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

SHELL= /bin/sh
DESTDIR= /usr/local/bin
WWWROOT= /usr/local/ns-home/docs
WWW= ${WWWROOT}/chongo/number
TARGETS= number.cgi number

all: ${TARGETS}

number.cgi: number.pl
	rm -f number.cgi
	cp number.pl number.cgi

number: number.pl
	rm -f number
	cp number.pl number
	chmod 0555 number

# NOTE: The cgi-bin/Makefile forms a symlink between the file:
#
#	${DOC_ROOT}/cgi-bin/nummber.cgi
#
# and our installation file:
#
#	${WWW}/number.cgi
#
# So thus we do NOT need to install number.pl into the cgi-bin directory
# if we do not have the ${WWW} directory.
#
install: all
	-@if [ -d ${WWW} ]; then \
	    echo "	install -m 0644 number ${WWW}"; \
	    install -m 0644 number ${WWW}; \
	    echo "	install -m 0755 number.cgi ${WWW}"; \
	    install -m 0755 number.cgi ${WWW}; \
	fi
	install -m 0555 number ${DESTDIR}

clean:

clobber: clean
	rm -f ${TARGETS}
