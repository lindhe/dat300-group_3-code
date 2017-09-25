## Implementation that outputs pairs of register IDs and values.
## Otherwise, the same restrictions as with pasad-simple apply.  Additionally,
## the correct register count is not checked and might lead to indexing errors.

module Pasad;

export {
	redef enum Log::ID += { LOG };

	type Info: record {
		start_address:	count	&log;
		quantity:	count	&log;
	};

	type Entry: record {
		address:	count &log;
		register:	count &log;
	};
}

redef record connection += {
	pasad: Info &optional;
};

event bro_init() &priority=5
	{
	Log::create_stream(Pasad::LOG, [$columns=Entry, $path="pasad-parsed"]);
	}

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_address: count, quantity: count)
	{
	c$pasad = [$start_address=start_address, $quantity=quantity];
	}

event modbus_read_holding_registers_response(c: connection, headers: ModbusHeaders, registers: ModbusRegisters)
	{
		local i = 0;
		while ( i < c$pasad$quantity )
			{
			local address = c$pasad$start_address + i;
			local mb_register = registers[i];
			local entry  = Entry($address=address, $register=mb_register);
			Log::write(Pasad::LOG, entry);
			++i;
			}
	}
