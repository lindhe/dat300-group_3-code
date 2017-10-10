#!/bin/bash

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

MIDBRO=${BRODIR}/broccoli/bin/midbropasad
MIDBROLOG=$(realpath midbro.log)

TMPDIR=$(mktemp --directory --tmpdir pasad.XXXX)

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
