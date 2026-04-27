#include "cuda_cracker.h"
#include <stdio.h>

__global__ void hello() {
    printf("Hello from thread%d\n", threadIdx.x);
}

void launch_hello() {
    hello<<<1, 10>>>();
    cudaDeviceSynchronize();
}