# Contents

The low-level operations on Q27 databases are implemented as stand-alone
C++ applications:

1. coronal2 - full exploration (of smaller board sizes) and database generation with a pre-placement of the two outer rings.
2. q27db - database statistics, inspection and merger.

Run both programs without arguments for a quick help on operation modes and
their parameters.

# Requirements

1. A C++-11 compiler - the provided Makefiles assume GNU Make using the GNU C++ compiler.
2. Boost Headers and Library (boost::iostreams).
