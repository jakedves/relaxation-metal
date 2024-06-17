//
//  main.swift
//  relaxation-swift
//
//  Created by Jake Davies on 15/06/2024.
//

import MetalKit

// Set up data on CPU

// as a guideline, the M1 has 8 cores, which recommended at least 8-16k threads
// Setting the matrixWidth to 100  => 10,000 threads
// Setting the matrixWidth to 1000 => 1,000,000 threads
// Equally, setting the matrixWidth to 1000 leads to 1,000,000 FP32 allocations => ~4GB memory
// but we need two matrices of the same size, so over 8GB of device memory
let matrixWidth = 5
var metalMatrixWidth = UInt32(matrixWidth)
let numElements = matrixWidth * matrixWidth

let initialMatrix = createDefaultSquareMatrix(Int(matrixWidth))

printMatrix(initialMatrix)


// Get reference to GPU, create a queue of commands, and access our available shader code
guard let device = MTLCreateSystemDefaultDevice() else {
    print("Could not create a Metal device")
    exit(EXIT_FAILURE)
}

guard let commandQueue = device.makeCommandQueue() else {
    print("Could not instantiate a command queue")
    exit(EXIT_FAILURE)
}

guard let gpuFunctionLibrary = device.makeDefaultLibrary() else {
    print("Could not instantiate the default library for the Metal device")
    exit(EXIT_FAILURE)
}

let relaxFuncName = "one_step" // name of our shader function
guard let relaxationStep = gpuFunctionLibrary.makeFunction(name: relaxFuncName) else {
    print("Could not find a kernel with the name: \(relaxFuncName)")
    exit(EXIT_FAILURE)
}

// Get "Compute Pipeline State" - information about using our GPU for general-purpose compute
var pipelineState: MTLComputePipelineState!
do {
    pipelineState = try device.makeComputePipelineState(function: relaxationStep)
} catch {
    print(error)
}

// Create a buffer that will store command information, and an encoder
// that can write to the buffer
var commandBuffer = commandQueue.makeCommandBuffer()

// device.makeBuffer() does allocation, and copying (when bytes provided)
// we want the readable and writeable buffers to only be available on the GPU
// as we will be purely number crunching with them
// however not sure how to setup with provided data, so will use shared memory for now
let fstBuffer = device.makeBuffer(
    bytes: initialMatrix,
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)!

let sndBuffer = device.makeBuffer(
    bytes: initialMatrix,
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)!

let widthValBuffer = device.makeBuffer(
    bytes: &metalMatrixWidth,
    length: MemoryLayout<Int>.size,
    options: .storageModeShared
)

// we want the convergence buffer to be shared as for now the CPU will
// read from it as the GPU writes to it
let convergenceBuffer = device.makeBuffer(
    length: MemoryLayout<UInt8>.size * numElements, // UInt8 and uint8_t are used for booleans TODO: check if reliable
    options: .storageModeShared
)

// Grids contain many threadgroups, arranged into (up to) 3 dimensional blocks
// When a kernel is dispatched, a grid is what is created for that kernel
let threadsPerGrid = MTLSize(width: matrixWidth, height: matrixWidth, depth: 1)

// The threadgroup is the "MIMD of SIMDs"
// A threadgroup often can have 1024 threads, organised into 32 thread SIMD groups
// Threadgroup threads can share memory, be syncronised via barriers, and so on
let maxThreadsPerThreadgroup = pipelineState.maxTotalThreadsPerThreadgroup
let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1) // TODO: how to determine size?

// setup variables for iterative process
// kernel called each iteration
var converged = false
var readableIndex = 2
var writableIndex = 3
var iteration = 0

while !converged {
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(pipelineState)
    
    // this code only managed lightweight references, no copying is done here
    commandEncoder?.setBuffer(widthValBuffer, offset: 0, index: 0)
    commandEncoder?.setBuffer(convergenceBuffer, offset: 0, index: 1)
    
    commandEncoder?.setBuffer(fstBuffer, offset: 0, index: readableIndex)
    commandEncoder?.setBuffer(sndBuffer, offset: 0, index: writableIndex)
    
    commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    commandEncoder?.endEncoding()
    commandBuffer?.commit() // sends the command to GPU for processing instantly
    commandBuffer?.waitUntilCompleted()
    
    // swap references to readable and writable buffer for GPU
    (readableIndex, writableIndex) = (writableIndex, readableIndex)
    
    // sequential convergence check on CPU, ideally move to GPU with parallel reduction
    converged = checkConverged(convergenceBuffer!, size: numElements)
    
    // printReadableMatrix(index: readableIndex, fstBuffer, sndBuffer)
    
    // create a new command buffer as previous was committed to queue
    commandBuffer = commandQueue.makeCommandBuffer()
    iteration += 1
}

// data we want is at the index: readableIndex
print("\(iteration) iterations")
printReadableMatrix(index: readableIndex, fstBuffer, sndBuffer)

relaxSequential(matrix: initialMatrix)
