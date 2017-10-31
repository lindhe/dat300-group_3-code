# Midbro – Packet Capturing for Intrusion Detection Systems

Created by Robert Gustafsson, Robin Krahl and Andreas Lindhé in DAT300 2017 at
Chalmers University of Technology. Copyright belongs to the authors.

## Dependencies

These dependencies are packaged in the Debian repositories, but are also
available on other platforms.

* Bro (`bro`)
* Broccoli (`libbroccoli-dev`)
* Tcpreplay (`tcpreplay`)

## Workflow

0. Compile and export library path
1. Start Bro
2. Start the consumer (midbro_test)
3. Send network traffic


## Example usage:

The commands below assume you are in the root directory of this repository.

### 0. Compile & export path

`make`
`export LD_LIBRARY_PATH=$(pwd)/lib`

**Example:** `make midbro_test`

### 1. Start Bro

`sudo bro -b -C -i lo script/mid.bro Log::default_writer=Log::WRITER_NONE`

### 2. Start the consumer (`midbro_test`)

`./bin/midbro_test`

### 3. Send network traffic

`sudo tcpreplay -i lo -M 100.0 livedata.cap`
