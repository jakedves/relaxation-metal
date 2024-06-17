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
