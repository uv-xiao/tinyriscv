#include <stdint.h>
#include "../include/utils.h"

int N = 1000;
int footprint = 1;

int main() {
    unsigned int a = 0;
    int i;

    for (i = 0; i < N; i++) {
        a += 1;
    }

    if (a == 1000)
        set_test_pass();
    else
        set_test_fail();
    
    return 0;
}