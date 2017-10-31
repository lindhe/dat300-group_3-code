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

# This function has to execute the given arguments on the target machine.
# For local execution, this could look like:
#     sudo bash -c "$@"
# Or for remote execution:
#     ssh -i ~/.ssh/id_rsa root@remote "$@"
# Make sure that the command is executed by root, and that root has
# ~/.ssh/id_rsa.
# Also note that the remote tests assumes no sudo password needed.

function execute_command {
	# bash -c "$@"
	ssh -i ~/.ssh/id_rsa pi@raspberry "sudo bash -c '$@'"
}

function measure_packets {
	TCPREPLAY_SPEED=$1
	TCPREPLAY_COUNT=$2

	BRO_PID=$(execute_command "bro -i \"${BRO_INTERFACE}\" -C -b Log::default_writer=Log::WRITER_NONE \"${BRO_SCRIPT}\" > ${BRO_DIR}/bro-out.txt 2> ${BRO_DIR}/bro-err.txt & echo \$!")

	IDS_PID=""
	if [[ -n "${IDS}" ]]
	then
		# Wait for Bro to be ready
		execute_command "tail -f ${BRO_DIR}/bro-err.txt | while read LOGLINE ; do [[ \"\${LOGLINE}\" == *\"listening on \"* ]] && pkill -P \$\$ tail ; done"
		# Start IDS
		IDS_PID=$(execute_command "${IDS} > ${BRO_DIR}/ids-out.txt 2> ${BRO_DIR}/ids-err.txt & echo \$!")
	fi

	tcpreplay -i ${TCPREPLAY_INTERFACE} -M ${TCPREPLAY_SPEED} -L ${TCPREPLAY_COUNT} ${TCPREPLAY_DUMP} > /dev/null 2> /dev/null

	PCPU="100.0"
	while [[ $(echo "${PCPU}>${IDLE}" | bc) -eq 1 ]]
	do
		sleep 1
		PCPU=$(execute_command "ps -q ${BRO_PID} -o pcpu --no-headers")
	done

	if [[ -n "${IDS_PID}" ]]
	then
		execute_command "kill -SIGINT \"${IDS_PID}\""
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
	echo "    $0 SCRIPT BIFACE DUMP TIFACE"
	echo "Arguments:"
	echo "    SCRIPT  the Bro script to execute"
	echo "    BIFACE  the interface for Bro to listen on"
	echo "    DUMP    the network dump to replay"
	echo "    TIFACE  the interface for tcpreplay to replay to"
	echo "    IDS     the IDS command to execute (optional)"
	exit 1
fi

BRO_SCRIPT=$1
BRO_INTERFACE=$2
TCPREPLAY_DUMP=$3
TCPREPLAY_INTERFACE=$4
IDS=""
if [[ $# -eq 5 ]]
then
	IDS=$5
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
IDLE=$(echo "${IDLECPU}+10" | bc);
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
