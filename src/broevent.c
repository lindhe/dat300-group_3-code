/*
 * Copyright 2017 Robert Gustafsson
 * Copyright 2017 Robin Krahl
 * Copyright 2017 Andreas Lindhé
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <unistd.h>

#include "fifoqueue.h"
#include "broevent.h"
#ifdef BROCCOLI
#include <broccoli.h>
#endif

char *host_default = "127.0.0.1";
char *port_default = "47760";
Fifo_q * q;

    static void
modbus_register_received(BroConn *conn, void *data, BroRecord *record)
{
    int type = BRO_TYPE_COUNT;
    uint64 *address = NULL;
    uint64 *value = NULL;

    // TODO: handle regtype
    address = bro_record_get_named_val(record, "address", &type);
    if (!address) {
        // TODO: handle error
        return;
    }
    value = bro_record_get_named_val(record, "register", &type);
    if (!value) {
        // TODO: handle error
        return;
    }
    #ifdef DEBUG
    printf("Received value %"PRIu64" from uid=%"PRIu64"\n",*value,*address);
    #endif

    add_to_queue(q, create_sensor_object(*value, *address));

    #ifdef DEBUG
    printf("Added to queue.\n");
    #endif
}

    void *
bro_event_listener(void * args)
{
    q = (Fifo_q *) args;
    int fd = -1;
    BroConn *bc = NULL;
    bro_init(NULL);
    char hostname[512];

    snprintf(hostname, 512, "%s:%s", host_default, port_default);
    if (! (bc = bro_conn_new_str(hostname, BRO_CFLAG_RECONNECT | BRO_CFLAG_ALWAYS_QUEUE)))
    {
        printf("Could not get Bro connection handle.\n");
        exit(-1);
    }
    bro_debug_calltrace = 0;
    bro_debug_messages  = 0;

    bro_event_registry_add(bc, "modbus_register_received",
            (BroEventFunc) modbus_register_received, NULL);

    while (! bro_conn_connect(bc))
    {
        printf("Could not connect to Bro at %s:%s.  Retrying in one second.\n",
            host_default, port_default);
        sleep(1);
    }

    fd =bro_conn_get_fd(bc);
    fd_set rfds;
    setbuf(stdout,NULL);

    while(true)
    {
        FD_ZERO(&rfds);
        FD_SET(fd,&rfds);
        if(select(fd+1,&rfds,NULL,NULL,NULL) == -1){
            printf("select(): Bad file descriptor");
            break;
        }

        bro_conn_process_input(bc);
    }

    bro_conn_delete(bc);
}
