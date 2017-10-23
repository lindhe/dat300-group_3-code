#!/bin/bash

# This function has to execute the given arguments on the target machine.
# For local execution, this could look like:
#     sudo bash -c "$@"
# Or for remote execution:
#     ssh -i ~/.ssh/id_rsa root@remote "$@"
# Make sure that the command is executed by root.

function execute_command {
	# bash -c "$@"
	ssh -i ~/.ssh/pasadpi_rsa pi@pasadpi2 "sudo bash -c '$@'"
}

function measure_packets {
	TCPREPLAY_SPEED=$1
	TCPREPLAY_COUNT=$2

	BRO_PID=$(execute_command "bro -i \"${BRO_INTERFACE}\" -C -b Log::default_writer=Log::WRITER_NONE \"${BRO_SCRIPT}\" > ${BRO_DIR}/bro-out.txt 2> ${BRO_DIR}/bro-err.txt & echo \$!")

	PASAD_PID=""
	if [[ -n "${PASAD}" ]]
	then
		# We also want to execute a Pasad instance
		# Wait for Bro to be ready
		execute_command "tail -f ${BRO_DIR}/bro-err.txt | while read LOGLINE ; do [[ \"\${LOGLINE}\" == *\"listening on \"* ]] && pkill -P \$\$ tail ; done"
		# Start Pasad
		PASAD_PID=$(execute_command "${PASAD} > ${BRO_DIR}/pasad-out.txt 2> ${BRO_DIR}/pasad-err.txt & echo \$!")
	fi

	tcpreplay -i ${TCPREPLAY_INTERFACE} -M ${TCPREPLAY_SPEED} -L ${TCPREPLAY_COUNT} ${TCPREPLAY_DUMP} > /dev/null 2> /dev/null

	PCPU="100.0"
	while [[ $(echo "${PCPU}>${IDLE}" | bc) -eq 1 ]]
	do
		sleep 1
		PCPU=$(execute_command "ps -q ${BRO_PID} -o pcpu --no-headers")
	done

	if [[ -n "${PASAD_PID}" ]]
	then
		execute_command "kill -SIGINT \"${PASAD_PID}\""
	fi
	execute_command "kill -SIGINT \"${BRO_PID}\""
	execute_command "while kill -0 ${BRO_PID} 2>/dev/null ; do sleep 0.1 ; done"

	execute_command "tail -1 ${BRO_DIR}/bro-err.txt" | sed 's/.* \([0-9]\+\) packets received.*/\1/'
}

if [[ $# -lt 4  || $# -gt 5 ]]
then
	echo "Executes Bro and tcpreplay and measures the number of packages"
	echo "received and handled by Bro."
	echo
	echo "Usage:"
	echo "    $0 SCRIPT BIFACE DUMP TIFACE [PASAD]"
	echo "Arguments:"
	echo "    SCRIPT  the Bro script to execute"
	echo "    BIFACE  the interface for Bro to listen on"
	echo "    DUMP    the network dump to replay"
	echo "    TIFACE  the interface for tcpreplay to replay to"
	echo "    PASAD   the Pasad command to execute (optional)"
	exit 1
fi

BRO_SCRIPT=$1
BRO_INTERFACE=$2
TCPREPLAY_DUMP=$3
TCPREPLAY_INTERFACE=$4
PASAD=""
if [[ $# -eq 5 ]]
then
	PASAD=$5
fi

SPEEDS=(100 50 25)
COUNTS=(1000000 2000000 4000000)

if [[ ! -r "${TCPREPLAY_DUMP}" ]]
then
	echo "The network dump '${TCPREPLAY_DUMP}' does not exist. Aborting."
	exit 1
fi

TCPREPLAY_DUMP=$(realpath "${TCPREPLAY_DUMP}")

BRO_DIR=$(execute_command "mktemp --directory --tmpdir bro.XXX")

# First run a test to measure what CPU base load to wait for
BRO_PID=$(execute_command "bro -i \"${BRO_INTERFACE}\" -C -b Log::default_writer=Log::WRITER_NONE \"${BRO_SCRIPT}\" > ${BRO_DIR}/bro-out.txt 2> ${BRO_DIR}/bro-err.txt & echo \$!")
sleep 10
IDLECPU=$(execute_command "ps -q ${BRO_PID} -o pcpu --no-headers")
IDLE=$(echo "${IDLECPU}+5.0" | bc);
echo "Idle baseload is: $IDLE";
execute_command "killall bro"

echo "Starting time: $(date +'%F_%T')"

echo -ne "sent\t"
for SPEED in ${SPEEDS[@]}
do
	echo -ne "${SPEED}\t"
done
echo "time"

for COUNT in ${COUNTS[@]}
do
	echo -ne "${COUNT}\t"
	for SPEED in ${SPEEDS[@]}
	do
		COUNT_RECEIVED=$(measure_packets ${SPEED} ${COUNT})
		echo -ne "${COUNT_RECEIVED}\t"
	done
    echo "$(date +'%F_%T')"
done

execute_command "rm -rf \"${BRO_DIR}\""
