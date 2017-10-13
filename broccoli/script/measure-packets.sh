#!/bin/bash

function measure_packets {
	TCPREPLAY_SPEED=$1
	TCPREPLAY_COUNT=$2

	bro -i "${BRO_INTERFACE}" -C -b Log::default_writer=Log::WRITER_NONE "${BRO_SCRIPT}" 2> bro-err.txt &
	BRO_PID=$!

	tcpreplay -i "${BRO_INTERFACE}" -M "${TCPREPLAY_SPEED}" -L "${TCPREPLAY_COUNT}" "${TCPREPLAY_DUMP}" > /dev/null 2> /dev/null

	PCPU="100.0"
	while [[ $(echo "${PCPU}>50" | bc) -eq 1 ]]
	do
		sleep 1
		PCPU=$(ps -q ${BRO_PID} -o pcpu --no-headers)
	done

	kill -SIGINT "${BRO_PID}"
	sleep 1

	tail -1 bro-err.txt | awk -F' ' '{print $5}'
}

if [[ $# -ne 3 ]]
then
	echo "Executes Bro and tcpreplay and measures the number of packages"
	echo "received and handled by Bro."
	echo
	echo "Usage:"
	echo "    $0 SCRIPT IFACE DUMP"
	echo "Arguments:"
	echo "    SCRIPT  the Bro script to execute"
	echo "    IFACE   the interface for Bro to listen on"
	echo "    DUMP    the network dump to replay"
	exit 1
fi

if [[ $(id -u) -ne 0 ]]
then
	echo "Must be run as root. Aborting."
	exit 1
fi

BRO_SCRIPT=$1
BRO_INTERFACE=$2
TCPREPLAY_DUMP=$3

SPEEDS=(400 200 100 50 25)
COUNTS=($(seq 400000 100000 2600000))

if [[ ! -r "${BRO_SCRIPT}" ]]
then
	echo "The Bro script '${BRO_SCRIPT}' does not exist. Aborting."
	exit 1
fi

if [[ ! -r "${TCPREPLAY_DUMP}" ]]
then
	echo "The network dump '${TCPREPLAY_DUMP}' does not exist. Aborting."
	exit 1
fi

BRO_SCRIPT=$(realpath "${BRO_SCRIPT}")
TCPREPLAY_DUMP=$(realpath "${TCPREPLAY_DUMP}")

BRO_DIR=$(mktemp --directory --tmpdir bro.XXX)

cd "${BRO_DIR}"

echo -ne "sent\t"
for SPEED in ${SPEEDS[@]}
do
	echo -ne "${SPEED}\t"
done
echo

for COUNT in ${COUNTS[@]}
do
	echo -ne "${COUNT}\t"
	for SPEED in ${SPEEDS[@]}
	do
		COUNT_RECEIVED=$(measure_packets ${SPEED} ${COUNT})
		echo -ne "${COUNT_RECEIVED}\t"
	done
	echo
done

rm -rf "${BRO_DIR}"
