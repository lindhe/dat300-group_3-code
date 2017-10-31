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

## Simple implementation that outputs the raw request and response data 
## to a log file.
## Currently, this only handles the read_holding_registers event.  Other
## events can be handled similarily.  This implementation assumes that
## requests and responses are exchanged within the same connection.  I am not
## sure whether this really holds.

module Midbro;

export {
	redef enum Log::ID += { LOG };

	type Info: record {
		ts_request:	time	&log;
		ts_response:	time	&log &optional;
		rtype: 		string	&log;
		tid_request:	count	&log;
		tid_response:	count	&log &optional;
		ip_orig:	addr	&log;
		ip_resp:	addr	&log;
		start_address:	count	&log;
		quantity:	count	&log;
		registers:	ModbusRegisters &log &optional;
	};
}

redef record connection += {
	midbro: Info &optional;
};

event bro_init() &priority=5
	{
	Log::create_stream(Midbro::LOG, [$columns=Info, $path="midbro-simple"]);
	}

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_address: count, quantity: count)
	{
	local rec: Info = [
		$ts_request=network_time(),
		$rtype="holding",
		$tid_request=headers$tid,
		$start_address=start_address,
		$quantity=quantity,
		$ip_orig=c$id$orig_h,
		$ip_resp=c$id$resp_h
	];
	c$midbro = rec;
	}

event modbus_read_holding_registers_response(c: connection, headers: ModbusHeaders, registers: ModbusRegisters)
	{
		c$midbro$tid_response = headers$tid;
		c$midbro$ts_response = network_time();
		c$midbro$registers = registers;
		Log::write(Midbro::LOG, c$midbro);
	}
