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
let matrix2 = createDefaultSquareMatrix(matrixWidth)

printMatrix(matrix1)


// MARK: Set up devices and pipeline

let device = MTLCreateSystemDefaultDevice()
let commandQueue = device?.makeCommandQueue()
let gpuFunctionLibrary = device?.makeDefaultLibrary()

let relaxFuncName = "relaxation" // name of our shader function

let relaxation = gpuFunctionLibrary?.makeFunction(name: relaxFuncName)

// we have the shader code we want to run, now need to create a pipeline
var pipelineState: MTLComputePipelineState! // can be nil, but assume unwrapped on access
do {
    pipelineState = try device?.makeComputePipelineState(function: relaxation!)
} catch {
    print(error)
}

// will be assigned to buffer(0)
let readableBuffer = device?.makeBuffer(
    bytes: matrix1,
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)

// will be assigned to buffer(1)
let writableBuffer = device?.makeBuffer(
    bytes: matrix2,
    length: MemoryLayout<Float>.size * numElements,
    options: .storageModeShared
)

