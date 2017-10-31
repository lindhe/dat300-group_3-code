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

    if (! bro_conn_connect(bc))
    {
        printf("Could not connect to Bro at %s:%s.\n", host_default,
                port_default);
        exit(-1);
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
