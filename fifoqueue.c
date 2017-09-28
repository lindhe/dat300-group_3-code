#include "includes/fifoqueue.h"

    Fifo_q * 
init_queue(int size)
{
    Fifo_q * q = (Fifo_q *) malloc(sizeof(Fifo_q));
    q->head = NULL;
    q->tail = NULL;
    q->maxSize = size;
    q->currentSize = 0;
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
    Queue_t * new_elem = (Queue_t *) malloc(sizeof(Queue_t *));
    new_elem->next = NULL;
    new_elem->sensor = sensor;
    if(is_empty(q))
        q->head = new_elem;
    else
        q->tail->next = new_elem;
    q->tail = new_elem;
    q->currentSize++;
    return 1;
}

    Sensor_t *
pop_from_queue(Fifo_q * q)
{
    if(is_empty(q)){
        perror("The queue is empty");
        exit(-1);
    }
    Queue_t * head = q->head;
    q->head = q->head->next;
    Sensor_t * sensor = head->sensor;
    free(head);
    q->currentSize--;
    return sensor;
} 

    void
print_queue(Fifo_q * q)
{
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
}
