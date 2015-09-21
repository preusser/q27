CPPFLAGS := -std=gnu++11 -Wall -O3
CC       := g++

.PHONY: all clean

all: coronal2 q27db
coronal2: DBEntry.o Symmetry.o
q27db: Database.o DBEntry.o Symmetry.o -lboost_iostreams

clean:
	rm -rf *~ *.o coronal2 q27db
