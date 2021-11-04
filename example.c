#include <stdio.h>
#include "memory.h"

int main() {
    memory_initialize();

    char* name = memory_allocate(4);
    name[0] = 'B';
    name[1] = 'o';
    name[2] = 'b';
    name[3] = '\0';

    printf("Hello, %s nice to meet you!\n", name);

    name = memory_reallocate(name, 6);
    name[3] = 'b';
    name[4] = 'y';
    name[5] = '\0';

    printf("I also go by %s.\n", name);

    memory_free(name);

    return 0;
}
