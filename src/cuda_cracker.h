#pragma once

#include <cstdint>
#include <cuda_runtime.h>

void run_cuda_bruteforce(
    uint64_t total,
    int length,
    const char* charset,
    const unsigned char* target,
    char* result,
    bool& found
);

void launch_hello();