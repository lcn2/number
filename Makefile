#!/usr/bin/env make
#
# number - print the English name of a number of any size
#
# Copyright (c) 1999-2014,2023,2024 by Landon Curt Noll.  All Rights Reserved.
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

SHELL= bash
INSTALL= install
TAR= tar
RM= rm
CP= cp
CHMOD= chmod

# locations
DESTBIN= /usr/local/bin

# what to build
TARGETS= number.cgi number number.tgz

all: ${TARGETS}

number.cgi: number.pl
	${RM} -f number.cgi
	${CP} number.pl number.cgi
	${CHMOD} 0555 number.cgi

number: number.pl
	${RM} -f number
	${CP} number.pl number
	${CHMOD} 0555 number

number.tgz: number.pl number.cgi number README.md
	${RM} -f number.tgz
	${TAR} -zcvf number.tgz number number.cgi README.md
	${CHMOD} 0444 number.tgz

install: all
	${INSTALL} -m 0555 number ${DESTBIN}

clean:

clobber: clean
	${RM} -f ${TARGETS}

# help
#
help:
	@echo make all
	@echo make install
	@echo make clobber
