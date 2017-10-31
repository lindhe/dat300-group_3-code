# Example usage:
# bro -b -C -i eth0 modbus.bro Log::default_writer=Log::WRITER_NONE
@load frameworks/communication/listen
@load base/protocols/modbus

module Pasad;

redef Pcap::bufsize = 256;

redef Communication::listen_port = 47760/tcp;

redef Communication::listen_ssl = F;

## Global variables
global verbose=F;

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

    const enable_filtering : bool = T;
    const filter_ip_addr : addr = 192.168.215.66;
    const filter_mem_addr : count = 64;
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
    if(verbose)
        print fmt("Received address=%d, register=%d", data$address, data$register);
}

event pasad_unmatched_response(tid: count) {
    if(verbose)
        print fmt("Unmatched response: tid=%d", tid);
}

## CUSTOM FUNCTIONS

function pasad_check_filter(ip: addr, start_address: count, quantity: count) : bool {
    if (!enable_filtering)
        return T;
    if (ip != filter_ip_addr)
        return F;

    if (start_address == 0 && quantity == 0)
        return T;
    if (start_address > filter_mem_addr)
        return F;
    return filter_mem_addr < start_address + quantity;
}

function pasad_generate_event(transaction: Transaction, c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters, regtype: string,
        i: count) {
    local data = RegisterData(
            $ip=c$id$resp_h,
            $uid=headers$uid,
            $regtype=regtype,
            $address=transaction$start_address + i,
            $register=registers[i]
    );
    event pasad_register_received(data);
}

function pasad_generate_events(transaction: Transaction, c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters, regtype: string) {
    # TODO: check registers size
    if (enable_filtering) {
        if(verbose)
            print fmt("%d   %d    %d", filter_mem_addr, transaction$start_address, transaction$quantity);
        pasad_generate_event(transaction, c, headers, registers, regtype,
                filter_mem_addr - transaction$start_address);
    } else {
        local i = 0;
        while (i < transaction$quantity) {
            pasad_generate_event(transaction, c, headers, registers, regtype, i);
            ++i;
        }
    }
}

## EVENT HANDLERS

event bro_init() &priority=5 {
    Log::create_stream(Pasad::LOG, [$columns=RegisterData, $path="pasad-parsed"]);
}

event modbus_read_holding_registers_request(c: connection,
        headers: ModbusHeaders, start_address: count, quantity: count) {
    if (!pasad_check_filter(c$id$resp_h, start_address, quantity)) {
        if(verbose)
            print fmt("Filtered %s/%d/%d", c$id$resp_h, start_address, quantity);
        return;
    }

    local tid = headers$tid;
    local transaction = Transaction(
            $start_address=start_address,
            $quantity=quantity
    );
    c$pasad$transactions[tid] = transaction;
}

event modbus_read_holding_registers_response(c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters) {
    if (!pasad_check_filter(c$id$resp_h, 0, 0)) {
        if(verbose)
            print fmt("Filtered %s", c$id$resp_h);
        return;
    }

    local tid = headers$tid;
    if (tid !in c$pasad$transactions) {
        event pasad_unmatched_response(tid);
        return;
    }
    local transaction = c$pasad$transactions[tid];
    delete c$pasad$transactions[tid];
    pasad_generate_events(transaction, c, headers, registers, "h");
}
