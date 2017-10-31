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

if [ $# -ne 3 ]
then
	echo "Extracts the data for one machine and one register from a Modbus dump"
	echo "and stores both the data and a plot in the current directory."
	echo
	echo "Usage: $0 DUMP IP ADDR"
	echo "Example: $0 livedata.cap 192.168.0.53 64"
	exit
fi

if [[ ! -f "$1" || ! -r "$1" ]]
then
	echo "Dump file $1 does not exist or cannot be read."
	exit
fi

CAPTURE_FILE=$(realpath "$1")
FILTER_MACHINE=$2
FILTER_REGISTER=$3

BRODIR=$(realpath "$(dirname "$0")/../..")
BROSCRIPT_BASE=${BRODIR}/script/modbus.bro

TMPDIR=$(mktemp --tmpdir --directory midbro.XXXX)
TMPDIR_BRO=${TMPDIR}/bro
BROSCRIPT_MOD=${TMPDIR}/modbus.bro

OUTDIR=$(pwd)
OUTFILE_DAT=${OUTDIR}/${FILTER_MACHINE}-${FILTER_REGISTER}.dat
OUTFILE_PNG=${OUTDIR}/${FILTER_MACHINE}-${FILTER_REGISTER}.png

echo " * Preparing Bro script ..."
cp "${BROSCRIPT_BASE}" "${BROSCRIPT_MOD}"
sed -ie "s/\(const enable_filtering : bool = \).*;/\1T;/g" "${BROSCRIPT_MOD}"
sed -ie "s/\(const filter_ip_addr : addr = \).*;/\1${FILTER_MACHINE};/g" "${BROSCRIPT_MOD}"
sed -ie "s/\(const filter_mem_addr : count = \).*;/\1${FILTER_REGISTER};/g" "${BROSCRIPT_MOD}"

echo " * Running Bro ..."
mkdir "${TMPDIR_BRO}"
cd "${TMPDIR_BRO}"
bro -r "${CAPTURE_FILE}" "${BROSCRIPT_MOD}" > /dev/null

echo " * Extracting data ..."
tail -n +9 "${TMPDIR_BRO}/midbro-parsed.log" | cut -f 5 > "${OUTFILE_DAT}"
echo "${OUTFILE_DAT}"

echo " * Generating graph ..."
echo "set terminal png; plot '${OUTFILE_DAT}' using 0:1 title '${FILTER_MACHINE} ${FILTER_REGISTER}'" | gnuplot > "${OUTFILE_PNG}"
echo "${OUTFILE_PNG}"

rm -r "${TMPDIR}"
