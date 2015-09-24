CPPFLAGS := -std=gnu++11 -Wall -O3
CC       := g++

.PHONY: all clean clobber

all: RangeParser.o IR.o

RangeParser.cpp RangeParser.hpp: RangeParser.ypp
	wisent $^

clean:
	rm -f *~ *.log *.o
clobber: clean
	rm -f RangeParser.cpp RangeParser.hpp
