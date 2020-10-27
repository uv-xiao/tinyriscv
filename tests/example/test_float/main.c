#include <stdint.h>
#include "../include/utils.h"



typedef float float32_t;

int main()
{

    float result;
    float a = 1.5;
    float b = 3.0;
    result = a + b;

    if (result - 4.5 < 0.0001 && result - 4.5 > -0.0001) 
        set_test_pass();
    else
        set_test_fail();

    return 0;
}
