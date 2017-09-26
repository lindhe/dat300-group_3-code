@load frameworks/communication/listen
module Pasad;

redef Communication::listen_port = 47760/tcp;

redef Communication::listen_ssl = F;

global response: event(register: count, uid: count);

redef Communication::nodes += {
	["pasad"] = [$host = 127.0.0.1, $events = /pasad/, $connect=F, $ssl=F]
};

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_adress: count, quantity: count)

{
    print fmt("Request: %d", quantity);
}

event modbus_read_holding_registers_response(c: connection, headers: ModbusHeaders, registers: ModbusRegisters)

{
    print fmt("Response: %d", registers[0]);
    event response(registers[0],headers$uid);
}

