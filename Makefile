#!/usr/bin/make
#
# number - number makefile
#
# @(#) $Revision: 1.22 $
# @(#) $Id: Makefile,v 1.22 2002/03/14 06:44:22 chongo Exp chongo $
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
SERVERROOT= /web/isthe/chroot
WWWROOT= ${SERVERROOT}/html
WWW= ${WWWROOT}/chongo/tech/math/number
CGIBIN= ${SERVERROOT}/cgi-bin
CGIBIN2= /var/www/cgi-bin/www.isthe.com

# who must own cgi scripts so that apache suexec will run them
#
CGI_USER= cgi
CGI_GROUP= cgi

# non-CGI stuff that must not be accessed by suexec
#
ALT_USER= chongo
ALT_GROUP= wwwadmin

# what to build
TARGETS= number.cgi number

all: ${TARGETS}

number.cgi: number.pl
	rm -f number.cgi
	cp number.pl number.cgi
	chmod 0555 number.cgi

number: number.pl
	rm -f number
	cp number.pl number
	chmod 0555 number

install: all
	${INSTALL} -m 0555 number ${DESTDIR}
	-@if [ -d ${WWW} ]; then \
	    echo "	${INSTALL} -o ${ALT_USER} -g ${ALT_GROUP} -m 0664 number ${WWW}"; \
	    ${INSTALL} -o ${ALT_USER} -g ${ALT_GROUP} -m 0664 number ${WWW}; \
	fi
	-@if [ -d ${CGIBIN} ]; then \
	    echo "	${INSTALL} -m 0555 -o ${CGI_USER} -g ${CGI_GROUP} number.cgi ${CGIBIN}"; \
	    ${INSTALL} -m 0555 -o ${CGI_USER} -g ${CGI_GROUP} number.cgi ${CGIBIN}; \
	fi
	-@if [ -d ${CGIBIN2} ]; then \
	    echo "	${INSTALL} -m 0555 -o ${CGI_USER} -g ${CGI_GROUP} number.cgi ${CGIBIN2}"; \
	    ${INSTALL} -m 0555 -o ${CGI_USER} -g ${CGI_GROUP} number.cgi ${CGIBIN2}; \
	fi

clean:

clobber: clean
	rm -f ${TARGETS}
