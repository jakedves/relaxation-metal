//
//  Relaxation.metal
//  relaxation-swift
//
//  Created by Jake Davies on 16/06/2024.
//

#include <metal_stdlib>
using namespace metal;

// the device address space is for persistent memory that the GPU can read/write
kernel void one_step(
                     device const uint *width     [[ buffer(0) ]],
                     device uint8_t *convergence  [[ buffer(1) ]],
                     device const float *readable [[ buffer(2) ]],
                     device float *writable       [[ buffer(3) ]],
                     uint2 gid      [[ thread_position_in_grid ]]
) {
    uint x = gid.x;
    uint y = gid.y;
    uint w = *width;
    uint bound = w - 1;
    
    uint index = x * w + y;
                         
    if (x == 0 || y == 0 || x == bound || y == bound) {
        convergence[index] = 1;
        return;
    }
    
    // average surrounding values and write to writable matrix
    float a = readable[(x + 1) * w + y];
    float b = readable[(x - 1) * w + y];
    float c = readable[index + 1];
    float d = readable[index - 1];
    
    float avg = (a + b + c + d) / 4.0;
    float previous = readable[index];
    float difference = fabs(previous - avg);
    
    writable[index] = avg;
    
    // Convergence check done on CPU
    // cannot do in threadgroups as can't all simultaneously write to same location
    // intermittent threadgroups could also overwrite each other
    // could write shader to perform parallel reduction with && operation but complex for now.
    bool converged = difference < 0.001;
    convergence[index] = converged ? 1 : 0;
}
