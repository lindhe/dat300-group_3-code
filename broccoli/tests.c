#include "includes/fifoqueue.h"
#include <assert.h>

    void
create_sensor_object_test() {   
    int value, uid;
    value = 1;
    uid = 2;
    Sensor_t * sensor = create_sensor_object(value, uid);
    assert(sensor->value == value);
    assert(sensor->uid == uid);
    printf("create_sensor_object_test SUCCESS\n");
    free(sensor);
}

    void
init_queue_test()
{   
    int size;
    Fifo_q * q;
    size = 50;
    q = init_queue(size);
    assert(q->maxSize == size);
    printf("init_queue_test SUCCESS\n");
    free(q);
}

    void
add_to_queue_test()
{
    int size, value, uid;
    Fifo_q * q;
    Sensor_t * sensor;
    size = 50;
    value = 1;
    uid = 2;
    q = init_queue(size);
    sensor = create_sensor_object(value, uid);
    add_to_queue(q,sensor);
    assert(q->currentSize == 1);
    assert(q->head->sensor == sensor);
    assert(q->tail->sensor == sensor);
    printf("add_to_queue_test SUCCESS\n");
    free(sensor);
    free(q->head);
    free(q);
}

    void
pop_from_queue_test()
{
    int size, value, uid;
    Fifo_q * q;
    Sensor_t * actual;
    Sensor_t * expected;
    size = 50;
    value = 1;
    uid = 2;
    q = init_queue(size);
    actual = create_sensor_object(value, uid);
    add_to_queue(q, actual);
    expected = pop_from_queue(q);
    assert(actual == expected);
    printf("pop_from_queue_test SUCCESS\n");
    free(actual);
    free(q->head);
    free(q);
}

    void
is_full_test()
{
    int size, value, uid;
    Fifo_q * q;
    Sensor_t * sensor;
    size = 1;
    value = 1;
    uid = 2;
    q = init_queue(size);
    sensor = create_sensor_object(value, uid);
    assert(is_full(q) == false);
    add_to_queue(q,sensor);
    assert(is_full(q) == true);
    printf("is_full_test SUCCESS\n");
    free(sensor);
    free(q->head);
    free(q);
}
    void
is_empty_test()
{
    int size, value, uid;
    Fifo_q * q;
    Sensor_t * sensor;
    size = 1;
    value = 1;
    uid = 2;
    q = init_queue(size);
    sensor = create_sensor_object(value, uid);
    assert(is_empty(q) == true);
    add_to_queue(q,sensor);
    assert(is_empty(q) == false);
    printf("is_empty_test SUCCESS\n");
    free(sensor);
    free(q->head);
    free(q);
}
    void
all_tests()
{
    create_sensor_object_test();
    init_queue_test();
    add_to_queue_test();
    pop_from_queue_test();
    is_full_test();
    is_empty_test();
    printf("TEST SUITE PASSED\n");
}
    int
main(int argc, char **argv)
{
    all_tests();
    return 0;
}
