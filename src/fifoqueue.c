/*
 * Copyright 2017 Robert Gustafsson
 * Copyright 2017 Robin Krahl
 * Copyright 2017 Andreas Lindhé
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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
    q->droppedValues = 0;
    q->largestBufferSize = 0;
    q->valuesReceived = 0;
    q->valuesReleased = 0;
    /*Queue empty from the beginning (block)*/
    sem_init(&q->bufferEmptyBlock, 0, 0);
    sem_init(&q->bufferFullBlock, 0, size);
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

    if(q == NULL){
        printf("Error: Queue not initialized\n");
        free(sensor); //free if not appended
        return -1;    
    } 
    /* Drop Least Recently or Drop Most Recently */
    #ifdef DLR
    if(is_full(q)){
        pop_from_queue(q);
        q->droppedValues++;
        return 0;
    }
    #else
    sem_wait(&q->bufferFullBlock);
    #endif
    sem_wait(&q->lock);
    Queue_t * new_elem = (Queue_t *) malloc(sizeof(Queue_t));
    new_elem->next = NULL;
    new_elem->sensor = sensor;
    if(is_empty(q)){
        q->head = new_elem;
    }else
        q->tail->next = new_elem;
    q->tail = new_elem;
    q->currentSize++;
    q->valuesReceived++;
    if(q->currentSize > q->largestBufferSize)
        q->largestBufferSize = q->currentSize;
    sem_post(&q->lock);
    sem_post(&q->bufferEmptyBlock);
    return 1;
}

    Sensor_t *
pop_from_queue(Fifo_q * q)
{
    int semStat;
    sem_wait(&q->bufferEmptyBlock);
    sem_wait(&q->lock);
    Queue_t * head = q->head;
    Sensor_t * sensor = head->sensor;
    /* If dequeue the last element */
    if(q->currentSize == 1){
        q->head = NULL;
        q->tail = NULL;
    }else{
        q->head = head->next;
    }
    free(head);
    q->currentSize--;
    q->valuesReleased++;
    sem_post(&q->lock);
    #ifndef DLR
    sem_post(&q->bufferFullBlock);
    #endif
    return sensor;
} 

    Sensor_t *
create_sensor_object(int value, int uid)
{
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
