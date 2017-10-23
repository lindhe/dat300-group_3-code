#!/bin/bash

if [[ $# -ne 1 ]]
then
	echo "Reads the sensor.dat and distance.dat from a running Pasad"
	echo "instance and draws a graph from them."
	echo
	echo "Usage:"
	echo "    $0 SOURCE"
	echo "Arguments:"
	echo "    SOURCE    an expression such that SOURCE/sensor.dat and"
	echo "              SOURCE/distance.dat can be used as arguments for"
	echo "              scp (e. g. user@host:/path/to/files)"
	echo
	echo "Note: Use ssh-add to avoid typing your SSH passphrase every second"
	exit 1
fi

function plot() {
	scp -i /home/andreas/.ssh/pasadpi_rsa -P 8022 "${SCP_EXPR}/sensor.dat" "${SCP_EXPR}/distance.dat" .
	echo "set terminal png; plot 'sensor.dat' using 0:1 with line, 'distance.dat' using 0:1 axis x1y2 with line"| gnuplot > live-tmp.png
	mv live-tmp.png live.png
}

SCP_EXPR=$1

echo 0 > sensor.dat
echo 0 > distance.dat
plot
feh -x --reload 0.1 live.png &

while true
do
	sleep 0.1
	plot
done
