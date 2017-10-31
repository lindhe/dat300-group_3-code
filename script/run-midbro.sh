#!/bin/bash

# Copyright 2017 Robert Gustafsson
# Copyright 2017 Robin Krahl
# Copyright 2017 Andreas Lindhé
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [ $# -ne 2 ]
then
	echo "Starts Bro with the given arguments in the background and, when"
	echo "it’s ready, starts Midbro."
	echo
	echo "Usage:   $0 INTERFACE SCRIPT"
	echo "Example: $0 lo modbus.bro"
	exit
fi

INTERFACE=$1
SCRIPT=$(realpath $2)

BRODIR=$(realpath "$(dirname "$0")/../..")
BROLOG=$(realpath bro.log)

MIDBRO=${BRODIR}/bin/midbro
MIDBROLOG=$(realpath midbro.log)

TMPDIR=$(mktemp --directory --tmpdir midbro.XXXX)

echo "* Starting Bro in background ..."
cd "${TMPDIR}" && sudo bro -i "${INTERFACE}" "${SCRIPT}" > ${BROLOG} 2>&1 &
BROPID=$!

echo "* Waiting for Bro to listen ..."
sleep 1
tail -f ${BROLOG} | while read LOGLINE
do
	[[ "${LOGLINE}" == "listening on "* ]] && pkill -P $$ tail
done

echo "* Starting Midbro ..."
${MIDBRO}

kill $BROPID

rm -r "${TMPDIR}"
