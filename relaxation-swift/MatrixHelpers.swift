//
//  MatrixHelpers.swift
//  relaxation-swift
//
//  Created by Jake Davies on 15/06/2024.
//

import MetalKit

/**
 Creates a matrix of the form:
 
 1 1 1 1 1
 1 0 0 0 0
 1 0 0 0 0
 1 0 0 0 0
 1 0 0 0 0
 
 for a given width (e.g. 5)
 
 */
func createDefaultSquareMatrix(_ width: Int) -> [Float] {
    var matrix = [Float](repeating: 0, count: width * width)
    
    for i in 0..<width {
        for j in 0..<width {
            matrix[i * width + j] = i == 0 || j == 0 ? 1.0 : 0.0
        }
    }
    
    return matrix
}

func printMatrix(_ matrix: [Float]) {
    let width = Int(sqrt(Double(matrix.count)))
    
    for i in 0..<width {
        for j in 0..<width {
            let number = matrix[i * width + j]
            print(String(format: "%.4f", number), terminator: " ")
        }
        print()
    }
    print()
}

func printMatrixFromBuffer(_ matrix: MTLBuffer) {
    // bytes / num of bytes a float takes up in array
    let bufferLength = matrix.length / MemoryLayout<Float>.stride
    let bufferPointer = matrix.contents().bindMemory(to: Float.self, capacity: bufferLength)
    let resultMatrix = Array(UnsafeBufferPointer(start: bufferPointer, count: bufferLength))

    printMatrix(resultMatrix)
}

func printReadableMatrix(index: Int, _ fst: MTLBuffer, _ snd: MTLBuffer) {
    printMatrixFromBuffer(index == 2 ? fst : snd)
}

// sequential approach on the CPU
func checkConverged(_ buffer: MTLBuffer, size: Int) -> Bool {
    let bufferPointer = buffer.contents().bindMemory(to: UInt8.self, capacity: size)
    
    for i in 0..<size {
        if bufferPointer[i] == 0 {
            return false
        }
    }
    
    return true
}

func identity<T>(_ value: T) -> T {
    return value
}

func relaxSequential(matrix: [Float]) {
    let width = Int(Double(matrix.count).squareRoot())
    var readable = matrix
    var writable = matrix
    var converged = Array(repeating: false, count: matrix.count)
    
    var iterations = 0
    
    var allConverged = false
    
    while !allConverged {
        for i in 0..<width {
            for j in 0..<width {
                let index = i * width + j
                
                if i == 0 || j == 0 || i == width - 1 || j == width - 1 {
                    converged[index] = true
                    continue
                }
                
                let a = readable[index + 1]
                let b = readable[index - 1]
                let c = readable[(i + 1) * width + j]
                let d = readable[(i - 1) * width + j]
                
                let avg = (a + b + c + d) / 4.0
                writable[index] = avg
                
                let previous = readable[index]
                let difference = abs(previous - avg)
                
                converged[index] = difference < 0.001
            }
        }
        
        iterations += 1
        
        // swap pointers
        (readable, writable) = (writable, readable)
        
        // check if all values are true
        allConverged = converged.allSatisfy(identity)
    }
    
    print("\(iterations) iterations")
    // printMatrix(readable)
}
