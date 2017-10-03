CC=gcc
CFLAGS =-c -DBROCCOLI
INC =-I/usr/local/include -I/usr/local/include -I./includes
LDFLAGS =  -L/usr/local/lib -lbroccoli -pthread
SRC = midbropasad.c broevent.c fifoqueue.c
OBJ = $(patsubst %.c, build/%.o, $(SRC))

all: bin/midbropasad bin/tests

bin/midbropasad: $(OBJ)
	$(CC) $^ -o bin/midbropasad $(LDFLAGS)

build/%.o: src/%.c
	$(CC) $(CFLAGS) $(INC) $< -o $@

bin/tests: build/fifoqueue.o build/tests.o
	$(CC) $^ -o bin/tests $(LDFLAGS)

build/tests.o: test/tests.c
	$(CC) $(CFLAGS) $(INC) $< -o $@

clean:
	rm build/* bin/*
