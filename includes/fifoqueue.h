#include <stdlib.h>
#include <stdio.h>
#include "types.h"

Fifo_q * init_queue(int size);

boolean is_full(Fifo_q * q);

boolean is_empty(Fifo_q * q);

int add_to_queue(Fifo_q * q, Sensor_t * sensor);

Sensor_t * pop_from_queue(Fifo_q * q);

void print_queue(Fifo_q * q);
