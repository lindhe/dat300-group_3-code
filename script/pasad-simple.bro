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
