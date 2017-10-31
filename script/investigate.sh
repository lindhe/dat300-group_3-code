#!/bin/bash

if [ $# -ne 3 ]
then
	echo "Extracts the data for one machine and one register from a Modbus dump"
	echo "and stores both the data and a plot in the current directory."
	echo
	echo "Usage: $0 DUMP IP ADDR"
	echo "Example: $0 packets_00014_20161128135616.cap 192.168.215.66 64"
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
BROSCRIPT_BASE=${BRODIR}/broccoli/script/modbus.bro

TMPDIR=$(mktemp --tmpdir --directory pasad.XXXX)
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
tail -n +9 "${TMPDIR_BRO}/pasad-parsed.log" | cut -f 5 > "${OUTFILE_DAT}"
echo "${OUTFILE_DAT}"

echo " * Generating graph ..."
echo "set terminal png; plot '${OUTFILE_DAT}' using 0:1 title '${FILTER_MACHINE} ${FILTER_REGISTER}'" | gnuplot > "${OUTFILE_PNG}"
echo "${OUTFILE_PNG}"

rm -r "${TMPDIR}"
