CC=gcc
LIBCFLAGS =-c -fPIC -DBROCCOLI
CFLAGS =-c -DBROCCOLI
INC =-I/usr/local/include -I/usr/local/include -I./includes
LDFLAGS =  -L/usr/local/lib -lbroccoli -pthread
SRC = midbropasad.c broevent.c fifoqueue.c
OBJ = $(patsubst %.c, build/%.o, $(SRC))

all: dirs bin/midbropasad

dirs:
	mkdir -p build bin lib

bin/midbropasad: $(OBJ)
	$(CC) -shared $^ -o lib/libmidbropasad.so $(LDFLAGS)

pasad_test:
	$(CC) test/pasad_test.c -I./includes -o bin/pasad_test -L./lib -lmidbropasad

build/%.o: src/%.c
	$(CC) $(LIBCFLAGS) $(INC) $< -o $@

bin/tests: build/fifoqueue.o build/tests.o
	$(CC) $^ -o bin/tests $(LDFLAGS)

build/tests.o: test/tests.c
	$(CC) $(CFLAGS) $(INC) $< -o $@

clean:
	rm build/* bin/*
