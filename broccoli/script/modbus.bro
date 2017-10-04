@load frameworks/communication/listen

module Pasad;

redef Communication::listen_port = 47760/tcp;

redef Communication::listen_ssl = F;

## DATA STRUCTURES

export {
    redef enum Log::ID += { LOG };

    type Transaction: record {
        start_address:  count;
        quantity:   count;
    };

    type TransactionTable: table[count] of Transaction;

    type Info: record {
        transactions:   TransactionTable    &default=TransactionTable();
    };

    type RegisterData: record {
        ip:         addr    &log;
        uid:        count   &log;
        regtype:    string  &log;
        address:    count   &log;
        register:   count   &log;
    };
}

redef record connection += {
    pasad: Info &default=Info();
};

redef Communication::nodes += {
    ["pasad"] = [$host = 127.0.0.1, $events = /pasad/, $connect=F, $ssl=F]
};

## CUSTOM EVENTS

event pasad_register_received(data: RegisterData) {
    Log::write(Pasad::LOG, data);
    print fmt("Received address=%d, register=%d", data$address, data$register);
}

event pasad_unmatched_response(tid: count) {
    print fmt("Unmatched response: tid=%d", tid);
}

## CUSTOM FUNCTIONS

function pasad_generate_events(transaction: Transaction, c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters, regtype: string) {
    # TODO: check registers size
    local i = 0;
    while (i < transaction$quantity) {
        local data = RegisterData(
                $ip=c$id$orig_h,
                $uid=headers$uid,
                $regtype=regtype,
                $address=transaction$start_address + i,
                $register=registers[i]
        );
        event pasad_register_received(data);
        ++i;
    }
}

## EVENT HANDLERS

event bro_init() &priority=5 {
    Log::create_stream(Pasad::LOG, [$columns=RegisterData, $path="pasad-parsed"]);
}

event modbus_read_holding_registers_request(c: connection,
        headers: ModbusHeaders, start_address: count, quantity: count) {
    local tid = headers$tid;
    local transaction = Transaction(
            $start_address=start_address,
            $quantity=quantity
    );
    c$pasad$transactions[tid] = transaction;
}

event modbus_read_holding_registers_response(c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters) {
    local tid = headers$tid;
    if (tid !in c$pasad$transactions) {
        event pasad_unmatched_response(tid);
        return;
    }
    local transaction = c$pasad$transactions[tid];
    delete c$pasad$transactions[tid];
    pasad_generate_events(transaction, c, headers, registers, "h");
}
