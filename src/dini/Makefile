DRIVER_DIR := linuxdrv-2.6
AELIB_DIR  := aelib
AELIB	   := $(AELIB_DIR)/libaelib.a

CXX      := g++
CC       := g++
CXXFLAGS := -std=gnu++11 -Wall -O2 -DLINUX -DNOCURSES -I$(AELIB_DIR) -I$(DRIVER_DIR) -fPIC
LDLIBS   := -lrt -lpthread


.PHONY: default clean

default: libdini.so

DiniBoard.o: CXXFLAGS += -I/opt/java/include -I/opt/java/include/linux

libdini.so: DiniBoard.o $(AELIB)
	$(CC) $(CFLAGS) -shared -o$@ $^

$(AELIB):
	$(MAKE) -C $(AELIB_DIR)

clean:
	$(MAKE) -C $(AELIB_DIR) clean
	rm -rf *~ *.o libdini.so
