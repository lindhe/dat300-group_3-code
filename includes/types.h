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
    int droppedValues;
    int largestBufferSize;
    int valuesReceived;
    int valuesReleased;
    sem_t bufferEmptyBlock;
    sem_t bufferFullBlock;
    sem_t lock;
};

#endif
