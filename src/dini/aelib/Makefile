BOARDS_SUPPORTED = -DSUPPORT_ALL -DSUPPORT_VIRTEX5 -DSUPPORT_VIRTEX6 -DSUPPORT_VIRTEX7 -DSUPPORT_STRATIX -DSUPPORT_SPARTAN6 -DSUPPORT_KINTEX7 -DSUPPORT_ULTRASCALE

SRC = $(wildcard *.cpp)
INC = $(wildcard *.h) $(wildcard *.hpp)
OBJS = $(SRC:.cpp=.o)

DRIVER_DIR = ../linuxdrv-2.6

CXX      := g++
CC       := g++
CXXFLAGS := -std=gnu++11 -Wall -O2 $(BOARDS_SUPPORTED) -DLINUX -DNOCURSES -I$(DRIVER_DIR) -fPIC

.PHONY: default clean

default: libaelib.a

libaelib.a: $(OBJS) Makefile
	ar rcs $@ $(OBJS)

%.o: %.cpp $(INC)

clean:
	rm -f *.o *.a
