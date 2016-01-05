CXXFLAGS := -std=gnu++11 -Wall -O3
CXX	 := g++
CC	 := g++

.PHONY: all range clean

all: coronal2 q27db
range/%:
	$(MAKE) -C range/ $*

coronal2: DBEntry.o Symmetry.o

q27db: LDLIBS += -lboost_iostreams
q27db: Database.o DBEntry.o Symmetry.o range/IR.o range/RangeParser.o

clean:
	$(MAKE) -C range/ clean
	rm -rf *~ *.o coronal2 q27db
