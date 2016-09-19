# The Q27 Project

The Q27 Project is a showcase for a massively parallel computation to tackle
an otherwise infeasible problem. It demonstrates the tremendous computational
power of designated circuit designs implemented on FPGA accelerators at the
example of enumerating and counting all the valid solutions of the
27-[Queens Puzzle](https://en.wikipedia.org/wiki/Eight_queens_puzzle). 

## Further Reading
* Pitch Presentation: [Putting Queens in Carry Chains &mdash; No. 27 &mdash;](pitch.pdf).
* Xcell Daily Blog: [Solving the N-Queens Puzzle for 27 Queens using FPGAs](https://forums.xilinx.com/t5/Xcell-Daily-Blog/Solving-the-N-Queens-Puzzle-for-27-Queens-using-FPGAs/ba-p/692248).
* [**Life Computation Status**](https://palios.inf.tu-dresden.de/q27status.php).

# Sponsors and Partners

**Wanted**: If you are willing to **contribute compute time** on your own
hardware or even to **donate devices**, please contact
thomas.preusser@tu-dresden.de.

Table of Contents
-----------------
 1. [License](#license)
 2. [News](#news)
 2. [Purpose](#purpose)
 3. [How to Contribute](#how-to-contribute)
 4. [Things To Do Alongside](#things-to-do-alongside)

------------------------------------------------------------------------------

## License
This project is licensed under the terms of the
[GNU Affero General Public License, Version 3](http://www.gnu.org/licenses/agpl.html).
A [verbatim copy](LICENSE.md) of the license document is contained within
this repository.

The VHDL implementation builds upon the
[PoC Library](https://github.com/VLSI-EDA/PoC), which is published
under the terms of the Apache 2.0 license.

## News
**Sep 19, 2016**:
Mission completed - there are **234907967154122528** solutions of the 27-Queens Puzzle. 29363791967678199, i.e. very slightly more than an eighth, of them had actually to be discovered by the computation running for slightly more than a year.

**Jan 22, 2016**:
The queens within the pre-placements advanced out of the overlap of west and
south pre-placing region. This virtually **broke a sound barrier**! While,
indeed, expecting an accelaration of the computation due to moving to more
constrained pre-placements now typically comprising eight (8) queens, the
observed **speedup of 10** was still an exciting surprise. Given the behavior
observed for the [26-Queens Puzzle](http://queens.inf.tu-dresden.de/?n=r)
as well as the 27-Queens Puzzle so far, a gradual slowdown must, however, be
expected from here: subtaks seem to yield more solutions and take longer to
compute as the pre-placed queens move closer to the center of their column.

**Jan 11, 2016**:
Triggered by the extremely different synthesis results obtained for
essentially the same FPGA devices found on the KC705 and the DNK7 FPGAs boards,
Vivado was given a chance for all Xilinx Gen-7 platforms. The results are
just **unbelievably amazing**:

* KC705: 67% more solvers, 7% faster clock, and
* VC707: 56% more solvers, 2% faster clock.

This is not just a different trade-off but truly tremendously better! The only shade of
a cloud that Vivado leaves is that it required a [workaround](https://github.com/preusser/q27/commit/cecaad8c833bd1d7687da831506cc1c2fa0228d6#diff-a84316ebb06574d233e2e751efbb43d4R84)
for dealing with physical VHDL types properly.

**Dec 2015**:
With our new multi-FPGA cluster setup and running, we hope to make considerable
computational progress over the holidays. (Yes, we let them labor hard while we
relax.) Check out the [performance figures](#how-to-contribute) to appreciate
their contribution.

## Purpose
Q27 demonstrates the tremendous power of compute accelerators provided through
FPGA resources.

1. **Training**: As the design virtually scales arbitrarily, it can be used:
  - to practice the performance tuning of large circuits cramped on
    filled FPGA devices, and
  - to practice trading off size (more solver slices) against
    clock speed (performance of a single solver).

2. **Engineering**: As the problem is heavily compute- rather than
   communication-bound, further optimization potential may be explored in:
  - moving the solver communication from the compute clock domain into the
    slow clock domain (which is currently only used for system services such
    as the fan control), and
  - using independent regional clock resources for subsets of the solver
    slices.

3. **Benchmarking**: Being able to tune the design size at a relatively fine
   granularity establishes a case for evaluating the resource balance of a
   device. For instance, it can be determined if the further growth of a
   design fails on routing or on logic resources or how fast the routing
   performance drops as the device is being cramped.

4. *Vanity*: Top our own [world record](http://queens.inf.tu-dresden.de/)
   from 2009 obtained by computing
   **Q(26)=22.317.699.616.364.044** using a similar distributed FPGA
   infrastructure.

## How to Contribute

1. **Check our Code**, find and report bugs: We are undertaking a massive,
   long-running computation. We put much effort in testing and eliminating
   bugs so as to avoid wasting computational effort. Any bug must be found
   as early as possible.
2. **Contribute Hardware**: We are currently computing using
   the idle time of the most powerful FPGA devices at the
   [VLSI-EDA Chair](http://vlsi-eda.inf.tu-dresden.de/) of
   [TU Dresden](http://www.tu-dresden.de/). While we,
   indeed, have powerful devices available, their number is
   rather small:

   Count | Board | Family | Device | Solvers | Clock | SE
   ------|-------|--------|--------|---------|-------|-----
   1x    | VC707 | Xilinx Virtex-7      | XC7VX485T-2     | 325 | 250.0 MHz | 812
         |(VC707)|(Xilinx Virtex-7)     |(XC7VX485T-2)    |(360)|(248.0 MHz)|(892)
   1x    | KC705 | Xilinx Kintex-7      | XC7K325T-2      | 250 | 284.4 MHz | 711
   1x    | ML605 | Xilinx Virtex-6      | XC6VLX240T-1    | 127 | 171.4 MHz | 217
   2x    | DE4   | Altera Stratix IV GX | EP4SGX230KF40C2 | 125 | 250.0 MHz | 312
   4x    | DNK7_F5_PCIe| Xilinx Kintex-7| 5x XC7K325T   | 5x240 | 220.0 MHz |2640

   **SE** (Solver Equivalent) - The performance of one solver slice running at 100 MHz.

   It appears the power supply on the VC707 board is failing us on the cramped
   Q27 design although computation picks up quite gently as problems arrive
   over the slow UART. This is why the maximum performance design is actually
   not in use.

   We will happily port to other powerful platforms!

   If you are willing to **contribute compute time** on your own hardware or
   even to **donate devices**, please contact thomas.preusser@tu-dresden.de.

In either case, you will have fully transparent access to all sources
through this site and will receive a honorable mention on this page.

## Things To Do Alongside

1. Use *Machine Learning* on the available solution counts of subproblems
   to build a predictor for the solution counts of subproblems yet to
   deal with. Such a predictor might help to describe and understand the
   patterns in the solution space.
2. Build a high-performance, highly-parallel solver using *GPGPU* technology
   as an alternative acceleration approach to contribute to this computation.
3. Design an interface to present and browse the completed subsolutions
   graphically.
4. Ultimately, find the *Formula* that directly computes the valid solution
   count from the problem size N.
