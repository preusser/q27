# Code Structure

The published sources comprise all aspects of the Q27 project infrastructure,
which are implemented in different languages:

1. C++
  - Stand-alone utilities:
     - to explore smaller N-Queens puzzles in software,
     - to generate a subproblem database, and
     - to analyze a subproblem database statistically.
  - Header files of potential general interest:
     - `endian.hpp` defining (u)intXXbe_t and (u)intXXle_t data types with
       a well-defined data width *and* memory layout. This is useful for
       for processing platform-independent memory-mapped data.
     - `uint128_t` containing a partial definition of a 128-bit unsigned
       integer data type.

2. VHDL
  - Implementation of hardware solvers for the exhaustive exploration of
    subproblems.
  - Top-level modules for various prototyping boards including the
    appropriate constraint files.

3. Java
  - The distributed backbone infrastructure comprising:
     - a central *Server* handing out subproblem specification to
     - distributed *Client*s relaying them to their locally attached
       FPGA devices.
  - A standalone *LocalMain* to serve local FPGAs from a local database
    for testing purposes.

# Building

The assumed build process is solely based on `make`. The `Makefile` recipes
are kept simplistic so that you can easily adapt them to the work flow of
your choice. The provided flow assumes:

1. a C++ compiler supporting C++11 and uses g++ by default,
2. the ISE-based `xflow` to synthesize the designs for Xilinx platforms, and
3. a Java8 environment.

# Database Format

The computation is managed through a custom database of subproblems.
The format of its entries is defined by the C++ header
[DBEntry.hpp](cpp/DBEntry.hpp). A Database is typically mapped into
memory and then used as an array of DBEntries. It is represented by the
classes [Database](cpp/Database.hpp) and
[MappedDatabase](java/me/preusser/q27/MappedDatabase.java) in C++ and Java,
respectively.
