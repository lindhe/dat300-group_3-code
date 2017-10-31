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

## Implementation that outputs the register identification and the register
## value. The correct register count is not checked and might lead to indexing
## errors.

module Midbro;

## DATA STRUCTURES

export {
	redef enum Log::ID += { LOG };

	type Transaction: record {
		start_address:	count;
		quantity:	count;
	};

	type TransactionTable: table[count] of Transaction;

	type Info: record {
		transactions:	TransactionTable	&default=TransactionTable();
	};

	type Entry: record {
		ip:		addr	&log;
		uid:		count	&log;
		regtype:	string	&log;
		address:	count	&log;
		register:	count	&log;
	};
}

redef record connection += {
	midbro: Info	&default=Info();
};

## CUSTOM EVENTS

event midbro_entry(entry: Entry)
	{
	Log::write(Midbro::LOG, entry);
	}

event midbro_unmatched(tid: count)
	{
	print fmt("Unmatched response: tid=%d", tid);
	}

## CUSTOM FUNCTIONS

function midbro_generate_events(transaction: Transaction, c: connection, headers: ModbusHeaders, registers: ModbusRegisters, regtype: string)
	{
	# TODO: check registers size
	local i = 0;
	while ( i < transaction$quantity )
		{
		local entry  = Entry(
			$ip=c$id$orig_h,
			$uid=headers$uid,
			$regtype=regtype,
			$address=transaction$start_address + i,
			$register=registers[i]
		);
		event midbro_entry(entry);
		++i;
		}
	}

## EVENT HANDLERS

event bro_init() &priority=5
	{
	Log::create_stream(Midbro::LOG, [$columns=Entry, $path="midbro-parsed"]);
	}

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_address: count, quantity: count)
	{
	local tid = headers$tid;
	local transaction = Transaction(
		$start_address=start_address,
		$quantity=quantity
	);
	c$midbro$transactions[tid] = transaction;
	}

event modbus_read_holding_registers_response(c: connection, headers: ModbusHeaders, registers: ModbusRegisters)
	{
	local tid = headers$tid;
	if ( tid !in c$midbro$transactions )
		{
		event midbro_unmatched(tid);
		return;
		}
	local transaction = c$midbro$transactions[tid];
	delete c$midbro$transactions[tid];
	midbro_generate_events(transaction, c, headers, registers, "h");
	}
