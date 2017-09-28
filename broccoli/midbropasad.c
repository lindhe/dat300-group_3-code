#include "includes/fifoqueue.h"
#include "includes/broevent.h"

    void
start_data_capture(Fifo_q * q)
{
    int res;
    pthread_t event_listener;
    res = pthread_create(&event_listener, NULL, bro_event_listener, q);
    if(res){
        perror("Unable to create thread");
        exit(-1);
    }
}

    int
main(int argc, char **argv)
{
    Fifo_q * q = init_queue(50);
    start_data_capture(q);
    while(true){
        printf("Main thread\n");
        sleep(2);
    }
    free(q);
    return 0;
}
