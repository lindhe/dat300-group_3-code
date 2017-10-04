#ifndef TYPES_H
#define TYPES_H
#include <semaphore.h>

#define true 1
#define false 0

typedef int boolean;
typedef struct sensor_t Sensor_t;
typedef struct queue_t Queue_t;
typedef struct fifo_q Fifo_q;

struct sensor_t{
    int uid;
    int value;
};

struct queue_t{
    Sensor_t * sensor;
    Queue_t * next;
};

struct fifo_q{
    Queue_t * head;
    Queue_t * tail;
    int maxSize;
    int currentSize;
    sem_t bufferEmptyBlock;
    sem_t lock;
};

#endif
