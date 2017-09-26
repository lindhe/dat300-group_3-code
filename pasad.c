#ifdef BROCCOLI
#include <broccoli.h>
#endif

char *host_default = "127.0.0.1";
char *port_default = "47760";

    static void
bro_pasad_response(BroConn *conn, void *data, uint64* registers, uint64* uid)
{
    printf("Received value %"PRIu64" from uid=%"PRIu64"\n",*registers,*uid);

    conn = NULL;
    data = NULL;
}

    int
main(int argc, char **argv)
{
    BroConn *bc;
    char hostname[512];
    int fd = -1;

    bro_init(NULL);

    bro_debug_calltrace = 0;
    bro_debug_messages  = 0;

    snprintf(hostname, 512, "%s:%s", host_default, port_default);

    if (! (bc = bro_conn_new_str(hostname, BRO_CFLAG_RECONNECT | BRO_CFLAG_ALWAYS_QUEUE)))
    {
        printf("Could not get Bro connection handle.\n");
        exit(-1);
    }
    bro_event_registry_add(bc, "response",(BroEventFunc) bro_pasad_response, NULL);

    if (! bro_conn_connect(bc))
    {
        printf("Could not connect to Bro at %s:%s.\n", host_default,
                port_default);
        exit(-1);
    }

    fd = bro_conn_get_fd(bc);
    fd_set rfds;
    setbuf(stdout,NULL);

    while(1)
    {
        FD_ZERO(&rfds);
        FD_SET(fd,&rfds);
        if(select(fd+1,&rfds,NULL,NULL,NULL) == -1){
            perror("select()");
            break;
        }

        bro_conn_process_input(bc);
    }

    bro_conn_delete(bc);

    return 0;
}
