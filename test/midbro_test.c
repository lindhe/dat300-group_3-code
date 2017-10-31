#include "midbro.h"

    int
main(int argc, char **argv)
{
    start_data_capture();
    while(1){
        request_value();
    }
    return 0;
}
