#include <pthread.h>
#include <unistd.h>
#include "fifoqueue.h"
#include "broevent.h"
#ifdef BROCCOLI
#include <broccoli.h>
#endif

Fifo_q * q;

    int *
request_sensor_data(int number)
{
    int i;
    int * arrayOfValues;
    Sensor_t * sensor;
    arrayOfValues = (int *) malloc(number*sizeof(int));
    for(i=0; i<number; ++i){
        sensor = pop_from_queue(q);
        arrayOfValues[i] = sensor->value;
        free(sensor);
    }
    printf("Release %d sensor data values\n", number);
    return arrayOfValues;
}

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
    sleep(10);
    while(true){
        print_queue(q);
        free(request_sensor_data(5));
    }
    free(q);
    return 0;
}
