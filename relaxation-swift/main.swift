//
//  main.swift
//  relaxation-swift
//
//  Created by Jake Davies on 15/06/2024.
//

import MetalKit

// MARK: Set up data on CPU

let matrixWidth = 5
let numElements = matrixWidth * matrixWidth

let matrix1 = createDefaultSquareMatrix(matrixWidth)

printMatrix(matrix1)


// MARK: Set up devices and pipeline

let device = MTLCreateSystemDefaultDevice()
let commandQueue = device?.makeCommandQueue()
let gpuFunctionLibrary = device?.makeDefaultLibrary()

let relaxationStep = "one_step" // name of our shader function

let relaxation = gpuFunctionLibrary?.makeFunction(name: relaxationStep)

// we have the shader code we want to run, now need to create a pipeline
var pipelineState: MTLComputePipelineState! // can be nil, but assume unwrapped on access
do {
    pipelineState = try device?.makeComputePipelineState(function: relaxation!)
} catch {
    print(error)
}

// Allocate memory in shared memory
// TODO: is it always shared memory between CPU/GPU? Only M-series surely?
let readableBuffer = device?.makeBuffer(
    bytes: matrix1,
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)

let writableBuffer = device?.makeBuffer(
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)

// MARK: idek
let commandBuffer = commandQueue?.makeCommandBuffer()
let commandEncoder = commandBuffer?.makeComputeCommandEncoder()

// set indices of buffers
commandEncoder?.setComputePipelineState(pipelineState)
commandEncoder?.setBuffer(readableBuffer, offset: 0, index: 0)
commandEncoder?.setBuffer(writableBuffer, offset: 0, index: 1)

// per grid (what is a grid), we want ...
let threadsPerGrid = MTLSize(width: matrixWidth, height: matrixWidth, depth: 1)
let maxThreadsPerThreadgroup = pipelineState.maxTotalThreadsPerThreadgroup

// TODO: What is this vs threadsPerGrid
let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)

commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
commandEncoder?.endEncoding()
commandBuffer?.commit()
commandBuffer?.waitUntilCompleted()

var resultPointer = readableBuffer?.contents().bindMemory(to: Float.self,
                                                          capacity: MemoryLayout<Float>.size * numElements
)

// TODO: need to iteratively
// 1. relax step
// 2. check convergence
// 3. swap pointers (saves memory allocation time) and repeat/exit
