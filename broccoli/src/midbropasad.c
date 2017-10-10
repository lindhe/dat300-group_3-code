#include <pthread.h>
#include <unistd.h>
#include "fifoqueue.h"
#include "broevent.h"
#ifdef BROCCOLI
#include <broccoli.h>
#endif

Fifo_q * q;

    void
request_n_values(int number, int arrayOfValues[])
{
    int i;
    Sensor_t * sensor;
    for(i=0; i<number; ++i){
        sensor = pop_from_queue(q);
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
    sensor = pop_from_queue(q);
    value = sensor->value;
    free(sensor);
    printf("Release 1 sensor data value\n");
    return value;
}

    void
start_data_capture()
{

    q = init_queue(50);
    int res;
    pthread_t event_listener;
    res = pthread_create(&event_listener, NULL, bro_event_listener, q);
    if(res){
        perror("Unable to create thread");
        exit(-1);
    }
}
