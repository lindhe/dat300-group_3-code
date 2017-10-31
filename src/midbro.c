#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include "fifoqueue.h"
#include "broevent.h"
#include "midbro.h"
#ifdef BROCCOLI
#include <broccoli.h>
#endif

Fifo_q * queue;
pthread_t event_listener;
sigset_t signal_set;

    void
sigint_handler(int signal)
{
    printf("\nStatistics:\n"
            "Total values received: %d\n"
            "Total values dropped: %d\n"
            "Total values released: %d\n"
            "Maximum buffer utilization: %d\n"
            "Buffer fixed size: %d\n"
            "Buffer size upon termination: %d\n",
            queue->valuesReceived, queue->droppedValues,
            queue->valuesReleased, queue->largestBufferSize,
            queue->maxSize, queue->currentSize);
    exit(0);
}
    void
request_n_values(int number, int arrayOfValues[])
{
    int i;
    Sensor_t * sensor;
    for(i=0; i<number; ++i){
        sensor = pop_from_queue(queue);
        arrayOfValues[i] = sensor->value;
        free(sensor);
    }
    printf("Release %d sensor data values\n", number);
}
    int
request_value()
{
    int value;
    Sensor_t * sensor;
    sensor = pop_from_queue(queue);
    value = sensor->value;
    free(sensor);
    printf("Release 1 sensor data value\n");
    return value;
}

    void
start_data_capture()
{
    int res;
    queue = init_queue(500); /* Initiate queue with fixed size */
    /* Create producer thread that listen for bro events */
    sigemptyset(&signal_set);
    sigaddset(&signal_set, SIGINT);
    res = pthread_sigmask(SIG_BLOCK, &signal_set, NULL);
    if(res != 0)
        perror("SIGINT block");
    res = pthread_create(&event_listener, NULL, bro_event_listener, queue);
    if(res){
        perror("Unable to create thread");
        exit(-1);
    }
    res = pthread_sigmask(SIG_UNBLOCK, &signal_set, NULL);
    if(res != 0)
        perror("SIGINT unblock");
    signal(SIGINT, sigint_handler);
}
