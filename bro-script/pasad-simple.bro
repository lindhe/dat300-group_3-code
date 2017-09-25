## Simple implementation that outputs the raw request and response data 
## to a log file.
## Currently, this only handles the read_holding_registers event.  Other
## events can be handled similarily.  This implementation assumes that
## requests and responses are exchanged within the same connection.  I am not
## sure whether this really holds.

module Pasad;

export {
	redef enum Log::ID += { LOG };

	type Info: record {
		ts_request:	time	&log;
		ts_response:	time	&log &optional;
		rtype: 		string	&log;
		tid_request:	count	&log;
		tid_response:	count	&log &optional;
		start_adress:	count	&log;
		quantity:	count	&log;
		registers:	ModbusRegisters &log &optional;
	};
}

redef record connection += {
	pasad: Info &optional;
};

event bro_init() &priority=5
	{
	Log::create_stream(Pasad::LOG, [$columns=Info, $path="pasad"]);
	}

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_adress: count, quantity: count)
	{
	local rec: Info = [$ts_request=network_time(), $rtype="holding", $tid_request=headers$tid, $start_adress=start_adress, $quantity=quantity];
	c$pasad = rec;
	}

event modbus_read_holding_registers_response(c: connection, headers: ModbusHeaders, registers: ModbusRegisters)
	{
		c$pasad$tid_response = headers$tid;
		c$pasad$ts_response = network_time();
		c$pasad$registers = registers;
		Log::write(Pasad::LOG, c$pasad);
	}
