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

if [[ $# -ne 1 ]]
then
	echo "Reads the sensor.dat and distance.dat"
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
	scp -i /path/to/id_rsa -P 8022 "${SCP_EXPR}/sensor.dat" "${SCP_EXPR}/distance.dat" .
	tail -1000 sensor.dat > sensor-1000.dat
	tail -1000 distance.dat > distance-1000.dat
	echo "set terminal png; set yrange [17000:17300]; set y2range [0:300]; set ytics nomirror; set y2tics nomirror; set title 'Midbro demo'; set ylabel 'sensor value'; set y2label 'distance'; plot 'sensor-1000.dat' using 0:1 with line title 'sensor value', 'distance-1000.dat' using 0:1 axis x1y2 with line title 'distance'" | gnuplot > live-tmp.png
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
