#include <stdint.h>
#include "../include/utils.h"

int N = 1001;
int footprint = 4;

int main() {
    unsigned int a = 0;
    int cnt = 0;
    int i;

    for (i = 0; i < N; i++, cnt++) {
        if (cnt == footprint) {
            a += 1;
            cnt = 0;
        }
    }

    if (a == 250)
        set_test_pass();
    else
        set_test_fail();
    
    return 0;
}