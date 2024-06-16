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
    
    uint width = 0; // TODO: remove
                         
    if (x == 0 || y == 0 || x == width || y == width) {
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
    
    // TODO: check for convergence (&& with a global converged flag?)
    bool converged = difference < 0.001;
    
    // TODO: CPU should swap references of readable and writable
}

kernel void relaxation() {}
