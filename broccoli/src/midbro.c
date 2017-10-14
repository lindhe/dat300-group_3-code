#include <pthread.h>
#include <unistd.h>
#include "fifoqueue.h"
#include "broevent.h"
#include "midbro.h"
#ifdef BROCCOLI
#include <broccoli.h>
#endif

Fifo_q * queue;

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
    queue = init_queue(500000); /* Initiate queue with fixed size */
    pthread_t event_listener;
    /* Create producer thread that listen for bro events */
    res = pthread_create(&event_listener, NULL, bro_event_listener, queue);
    if(res){
        perror("Unable to create thread");
        exit(-1);
    }
}
