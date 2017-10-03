#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include "types.h"
#include "fifoqueue.h"

pthread_mutex_t lock;
pthread_mutex_t bufferEmptyBlock;

    Fifo_q * 
init_queue(int size)
{
    Fifo_q * q = (Fifo_q *) malloc(sizeof(Fifo_q));
    q->head = NULL;
    q->tail = NULL;
    q->maxSize = size;
    q->currentSize = 0;
    if (pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("WARNING: Couldn't initialize lock\n");
    }
    if (pthread_mutex_init(&bufferEmptyBlock, NULL) != 0)
    {
        printf("WARNING: Couldn't initialize blocking lock\n");
    }
    pthread_mutex_lock(&bufferEmptyBlock);
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

    pthread_mutex_lock(&lock);
    /* TODO delete first one if full */
    if(q == NULL){
        return -1;    
    } 
    else if(is_full(q)){
        return -1;
    }
    Queue_t * new_elem = (Queue_t *) malloc(sizeof(Queue_t));
    new_elem->next = NULL;
    new_elem->sensor = sensor;
    if(is_empty(q)){
        q->head = new_elem;
        pthread_mutex_unlock(&bufferEmptyBlock);
    }else
        q->tail->next = new_elem;
    q->tail = new_elem;
    q->currentSize++;
    pthread_mutex_unlock(&lock);
    return 1;
}

    Sensor_t *
pop_from_queue(Fifo_q * q)
{

    if(is_empty(q)){
        perror("The queue is empty");
        pthread_mutex_lock(&bufferEmptyBlock);
    }
    pthread_mutex_lock(&lock);
    Queue_t * head = q->head;
    q->head = head->next;
    Sensor_t * sensor = head->sensor;
    free(head);
    q->currentSize--;
    pthread_mutex_unlock(&lock);
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
    pthread_mutex_lock(&lock);
    Queue_t * current = q->head;
    if(current == NULL){
        printf("The queue is empty!");
        return;
    }
    while(current != NULL){
        printf("sensor value=%d, sensor uid=%d\n",
                current->sensor->value, current->sensor->uid);
        current = current->next;
    }
    pthread_mutex_unlock(&lock);
}
