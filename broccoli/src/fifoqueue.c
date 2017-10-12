#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <semaphore.h>
#include "types.h"
#include "fifoqueue.h"

    Fifo_q * 
init_queue(int size)
{
    Fifo_q * q = (Fifo_q *) malloc(sizeof(Fifo_q));
    q->head = NULL;
    q->tail = NULL;
    q->maxSize = size;
    q->currentSize = 0;
    sem_init(&q->bufferEmptyBlock, 0, 0);
    sem_init(&q->lock, 0, 1);
    return q;
}

    boolean
is_full(Fifo_q * q)
{
    if(q->currentSize < q->maxSize)
        return false;
    else
        return true;
}  

    boolean
is_empty(Fifo_q * q)
{
    if(q->head==NULL)
        return true;
    else
        return false; 
}

    int
add_to_queue(Fifo_q * q, Sensor_t * sensor)
{

    /* TODO delete first one if full */
    if(q == NULL){
        return -1;    
    } 
    else if(is_full(q)){
        return -1;
    }
    sem_wait(&q->lock);
    Queue_t * new_elem = (Queue_t *) malloc(sizeof(Queue_t));
    new_elem->next = NULL;
    new_elem->sensor = sensor;
    if(is_empty(q)){
        q->head = new_elem;
        sem_post(&q->bufferEmptyBlock);
    }else
        q->tail->next = new_elem;
    q->tail = new_elem;
    q->currentSize++;
    sem_post(&q->lock);
    return 1;
}

    Sensor_t *
pop_from_queue(Fifo_q * q)
{
    int semStat;
    if(is_empty(q)){
        #ifdef DEBUG
        printf("Waiting for sensor data\n");
        #endif
        sem_wait(&q->bufferEmptyBlock);
    }
    sem_wait(&q->lock);
    Queue_t * head = q->head;
    Sensor_t * sensor = head->sensor;
    if(q->currentSize == 1){
        q->head = NULL;
        q->tail = NULL;
        sem_getvalue(&q->bufferEmptyBlock, &semStat);
        if(semStat == 1)
            sem_wait(&q->bufferEmptyBlock);
    }else{
        q->head = head->next;
    }
    free(head);
    q->currentSize--;
    sem_post(&q->lock);
    return sensor;
} 

    Sensor_t *
create_sensor_object(int value, int uid){
    Sensor_t * sensor = (Sensor_t *) malloc(sizeof(Sensor_t));
    sensor->value = value;
    sensor->uid = uid;
    return sensor;
}
    void
print_queue(Fifo_q * q)
{
    sem_wait(&q->lock);
    Queue_t * current = q->head;
    printf("\nContent of the queue with size=%d\n",q->currentSize);
    if(current == NULL){
        printf("The queue is empty!\n");
        sem_post(&q->lock);
        return;
    }
    while(current != NULL){
        printf("sensor value=%d, sensor uid=%d\n",
                current->sensor->value, current->sensor->uid);
        current = current->next;
    }
    sem_post(&q->lock);
}
