#!/usr/bin/make
#
# number - number makefile
#
# @(#) $Revision: 1.18 $
# @(#) $Id: Makefile,v 1.18 1999/10/22 10:03:01 chongo Exp chongo $
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
INSTALL= install

# locations
DESTDIR= /usr/local/bin
SERVERROOT= /usr/local/ns-home
WWWROOT= ${SERVERROOT}/docs
WWW= ${WWWROOT}/chongo/tech/math/number
CGIBIN= ${SERVERROOT}/cgi-bin
EXTCGIBIN= ${WWWROOT}/chongo/cgi-bin

# what to build
TARGETS= number.cgi number

all: ${TARGETS}

number.cgi: number.pl
	rm -f number.cgi
	cp number.pl number.cgi

number: number.pl
	rm -f number
	cp number.pl number
	chmod 0555 number

install: all
	${INSTALL} -m 0555 number ${DESTDIR}
	-@if [ -d ${WWW} ]; then \
	    echo "	${INSTALL} -m 0644 number ${WWW}"; \
	    ${INSTALL} -m 0644 number ${WWW}; \
	fi
	-@if [ -d ${CGIBIN} ]; then \
	    echo "	${INSTALL} -m 0555 number.cgi ${CGIBIN}"; \
	    ${INSTALL} -m 0555 number.cgi ${CGIBIN}; \
	fi
	-@if [ -d ${EXTCGIBIN} ]; then \
	    echo "${INSTALL} -m 0755 number.cgi ${EXTCGIBIN}"; \
	    ${INSTALL} -m 0755 number.cgi ${EXTCGIBIN}; \
	    echo "${INSTALL} -m 0644 number.cgi ${EXTCGIBIN}/number.cgi.txt"; \
	    ${INSTALL} -m 0644 number.cgi ${EXTCGIBIN}/number.cgi.txt; \
	fi

clean:

clobber: clean
	rm -f ${TARGETS}
