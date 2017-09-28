#include "includes/fifoqueue.h"
#include "includes/broevent.h"

    int
main(int argc, char **argv)
{
    Fifo_q * q = init_queue(5);
    bro_event_listener();

    free(q);
    return 0;
}
