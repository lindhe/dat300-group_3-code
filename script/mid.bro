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

# Example usage:
# bro -b -C -i eth0 modbus.bro Log::default_writer=Log::WRITER_NONE
@load frameworks/communication/listen
@load base/protocols/modbus

module Midbro;

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
    midbro: Info &default=Info();
};

redef Communication::nodes += {
    ["midbro"] = [$host = 127.0.0.1, $events = /midbro/, $connect=F, $ssl=F]
};

## CUSTOM EVENTS

event modbus_register_received(data: RegisterData) {
    Log::write(Midbro::LOG, data);
    if(verbose)
        print fmt("Received address=%d, register=%d", data$address, data$register);
}

event modbus_unmatched_response(tid: count) {
    if(verbose)
        print fmt("Unmatched response: tid=%d", tid);
}

## CUSTOM FUNCTIONS

function modbus_check_filter(ip: addr, start_address: count, quantity: count) : bool {
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

function midbro_generate_event(transaction: Transaction, c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters, regtype: string,
        i: count) {
    local data = RegisterData(
            $ip=c$id$resp_h,
            $uid=headers$uid,
            $regtype=regtype,
            $address=transaction$start_address + i,
            $register=registers[i]
    );
    event modbus_register_received(data);
}

function midbro_generate_events(transaction: Transaction, c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters, regtype: string) {
    # TODO: check registers size
    if (enable_filtering) {
        if(verbose)
            print fmt("%d   %d    %d", filter_mem_addr, transaction$start_address, transaction$quantity);
        midbro_generate_event(transaction, c, headers, registers, regtype,
                filter_mem_addr - transaction$start_address);
    } else {
        local i = 0;
        while (i < transaction$quantity) {
            midbro_generate_event(transaction, c, headers, registers, regtype, i);
            ++i;
        }
    }
}

## EVENT HANDLERS

event bro_init() &priority=5 {
    Log::create_stream(Midbro::LOG, [$columns=RegisterData, $path="midbro-parsed"]);
}

event modbus_read_holding_registers_request(c: connection,
        headers: ModbusHeaders, start_address: count, quantity: count) {
    if (!midbro_check_filter(c$id$resp_h, start_address, quantity)) {
        if(verbose)
            print fmt("Filtered %s/%d/%d", c$id$resp_h, start_address, quantity);
        return;
    }

    local tid = headers$tid;
    local transaction = Transaction(
            $start_address=start_address,
            $quantity=quantity
    );
    c$midbro$transactions[tid] = transaction;
}

event modbus_read_holding_registers_response(c: connection,
        headers: ModbusHeaders, registers: ModbusRegisters) {
    if (!midbro_check_filter(c$id$resp_h, 0, 0)) {
        if(verbose)
            print fmt("Filtered %s", c$id$resp_h);
        return;
    }

    local tid = headers$tid;
    if (tid !in c$midbro$transactions) {
        event midbro_unmatched_response(tid);
        return;
    }
    local transaction = c$midbro$transactions[tid];
    delete c$midbro$transactions[tid];
    midbro_generate_events(transaction, c, headers, registers, "h");
}
