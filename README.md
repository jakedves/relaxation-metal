# Relaxation in Metal

This repository implements the "relaxation technique" in Metal, Apple's GPU framework.

The relaxation technique is a method for solving differential equations for weather forecasting, etc. The problem is replacing each element of a matrix, by the average of its four neighbours until convergence, besides boundary elements. An example step shown below:

<table>
  <tr>
    <td>
      <table border="1">
        <tr>
          <td>1</td><td>1</td><td>1</td><td>1</td>
        </tr>
        <tr>
          <td>1</td><td>0</td><td>0</td><td>0</td>
        </tr>
        <tr>
          <td>1</td><td>0</td><td>0</td><td>0</td>
        </tr>
        <tr>
          <td>1</td><td>0</td><td>0</td><td>0</td>
        </tr>
      </table>
    </td>
    <td>
      <table border="1">
        <tr>
          <td>1</td><td>1</td><td>1</td><td>1</td>
        </tr>
        <tr>
          <td>1</td><td>0.5</td><td>0.25</td><td>0</td>
        </tr>
        <tr>
          <td>1</td><td>0.25</td><td>0</td><td>0</td>
        </tr>
        <tr>
          <td>1</td><td>0</td><td>0</td><td>0</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

For large matrices, it makes sense to do this computation in parallel. It is very easy to implement this sequentially, but is a great problem for learning parallel computing frameworks as it involves:

- Careful use of thread creation
- Careful use of memory management
- Pointers and 2D matrices
- Syncronization

This repository implements the relaxation technique in Metal Compute (parallel) and Swift (sequentially). The two implementations are compared for correctness.

## Design

The goal of a GPU program is to reduce branching computation, as a GPU is essentially many SIMD processors, which all have to take the longest codepath. This means if we had 32 threads and only took a really long codepath, they would all be using cores for the time of that codepath - wasting time.

<div align='center'>
  <img src="https://github.com/jakedves/relaxation-metal/assets/75232368/cd11d191-74d5-4652-bc66-9c8c388b43ee" width="300"/>
</div>

We've taken the whole matrix to be the grid (2D), and have allocated thread groups as 1D lines, as the SIMD groups inside of them will follow the same codepath. At boundaries, most SIMD groups will all return early.

Currently each thread writes to an array to say if it has converged. The CPU checks if all the values in the array are `true` (slow). A better design would use a parallel reduction on the GPU, possibly after computing a local 'threadgroup converged' flag for each threadgroup.

Launching kernels for each step should be efficient after the first iteration, as Metal keeps a compiler cache of kernel code [[source]](https://stackoverflow.com/a/63732727). The memory is shared so it is a question of whether ownership transfer is expensive or not (unlikely?).

## Results

Speedup, times in seconds (6 d.p) over three runs:

| Elements    | CPU          | GPU        | Speedup |
| ----------- | ------------ | ---------- | --------- |
| 100         |     0.006444 |   0.029316 |  0.22 |
| 10,000      |     2.625666 |   0.282057 |  9.31 |
| 1,000,000   |   244.828203 |   3.729596 | 65.64 |
| 100,000,000 | 24402.954380 | 566.576137 | 43.07 |

Configuration:
```
MacBook Pro 13" 2020
1.4 GHz Quad-Core Intel Core i5
Intel Iris Plus Graphics 645 1536 MB
8 GB 2133 MHz LPDDR3
```

