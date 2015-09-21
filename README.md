# The Q27 Project

The Q27 Project is a showcase for a massively parallel computation to tackle
an otherwise infeasible problem. It demonstrates the tremendous computational
power of designated circuit designs implemented on FPGA accelerators at the
example of enumerating and couting all the valid solutions of the
27-[Queens Puzzle](https://en.wikipedia.org/wiki/Eight_queens_puzzle). 

Table of Contents
-----------------
 1. [License](#license)
 2. [Purpose](#purpose)
 3. [How to Contribute](#how-to-contribute)

------------------------------------------------------------------------------

## License
This project is licensed under the terms of the
[GNU GENERAL PUBLIC LICENSE, Version 3](https://www.gnu.org/licenses/gpl.html).
A [verbatim copy](LICENSE) of the license document is contained within
this repository.

The VHDL implementation builds upon the
[PoC Library](https://github.com/VLSI-EDA/PoC), which is published
under the terms of the Apache 2.0 license.

## Purpose
Q27 demonstrates the tremendous power of compute accelerators provided through
FPGA resources.

1. As the design virtually scales arbitrarily, it can be used:
  - to practice the performance tuning of large circuits cramped on
    filled FPGA devices, and
  - to practice trading off size (more solver slices) against
    clock speed (performance of a single solver).

2. As the problem is heavily compute- rather than communication-bound, further
   optimzation potential may be explored in:
  - moving the solver communication from the compute clock domain into the
    slow clock domain (which is currently only used for system services such
    as the fan control), and
  - using independent regional clock resources for subsets of the solver
    slices.

3. Top our own [world record](http://queens.inf.tu-dresden.de/)
   from 2009 obtained by computing
   **Q(26)=22.317.699.616.364.044** using a similar distributed FPGA
   infrastructure.

## How to Contribute

1. **Check our Code**, find and report bugs: We are undertaking a massive,
   long-running computation. We put much effort in testing and eliminating
   bugs so as to avoid wasting computational effort. Any bug must be found
   as early as possible.
2. **Contribute Hardware**: We are computing using the idle time of the
   most powerful FPGA devices at the VLSI-EDA Chair of TU Dresden. While we
   have, indeed, have powerful devices available, their number is fairly
   small:

   Count | Board | Family | Device | Solvers | Clock | SE
   ------|-------|--------|--------|---------|-------|-----
   1x    | VC707 | Xilinx Virtex-7 | XC7VX485T-2 | 215 | 251.4 MHz | 540
   1x    | KC705 | Xilinx Kintex-7 | XC7K325T-2  | 144 | 271.4 MHz | 390
   1x    | ML605 | Xilinx Virtex-6 | XC6VLX240T-1| 125 | 200.0 MHz | 250

   **SE** (Solver Equivalent) - The preformance of one solver slice running at 100 MHz.

   If you are willing to **contribute compute time** on your own hardware or
   even to **donate devices**, please contact thomas.preusser@tu-dresden.de.
