//
//  Relaxation.metal
//  relaxation-swift
//
//  Created by Jake Davies on 16/06/2024.
//

#include <metal_stdlib>
using namespace metal;


kernel void one_step(
                     device const float *readable [[ buffer(0) ]],
                     device float *writable [[ buffer(1) ]],
                     uint2 gid [[ thread_position_in_grid ]]
                     )
{
    uint x = gid.x;
    uint y = gid.y;
    
    uint width = 0; // TODO: remove, pass reference to width value
                         
    if (x == 0 || y == 0 || x == width - 1 || y == width - 1) {
        return;
    }
    
    // average surrounding values and write to writable matrix
    // TODO: Update indices
    float a = readable[0];
    float b = readable[0];
    float c = readable[0];
    float d = readable[0];
    
    float avg = (a + b + c + d) / 4.0;
    float previous = readable[0];
    float difference = abs(previous - avg);
    
    writable[0] = avg;
    
    // TODO: check for convergence (&& with a global converged flag?) can't do as imagine:
    // thread 1: read global flag, computes global && local as true
    // thread 2: read global flag, computes global && local as false
    // thread 2: write false to global flag
    // thread 1: overwrites global flag to true
    bool converged = difference < 0.001;
    
    // TODO: CPU should swap references of readable and writable
}

kernel void relaxation() {}
