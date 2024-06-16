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
                     device const uint *width [[ buffer(0) ]],
                     device const float *readable [[ buffer(1) ]],
                     device float *writable [[ buffer(2) ]],
                     uint2 gid [[ thread_position_in_grid ]]
                     )
{
    uint x = gid.x;
    uint y = gid.y;
                         
    if (x == 0 || y == 0 || x == *width - 1 || y == *width - 1) {
        return;
    }
    
    uint w = *width;
    
    // average surrounding values and write to writable matrix
    float a = readable[(x + 1) * w + y];
    float b = readable[(x - 1) * w + y];
    float c = readable[x * w + y + 1];
    float d = readable[x * w + y - 1];
    
    float avg = (a + b + c + d) / 4.0;
    float previous = readable[0];
    float difference = abs(previous - avg);
    
    writable[0] = avg;
    
    // TODO: check for convergence on CPU
    // cannot do in threadgroups as can't all simultaneously write to same location
    // intermittent threadgroups could also overwrite each other
    // could write shader to perform parallel reduction with && operation but complex for now.
    bool converged = difference < 0.001;
    
    // TODO: CPU should swap references of readable and writable
}
