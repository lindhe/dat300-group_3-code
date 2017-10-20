CC=gcc
LIBCFLAGS =-c -fPIC -DBROCCOLI
CFLAGS =-c -DBROCCOLI
INC =-I/usr/local/include -I/usr/local/include -I./includes
LDFLAGS =  -L/usr/local/lib -lbroccoli -pthread
DEBUG =
SRC = midbro.c broevent.c fifoqueue.c
OBJ = $(patsubst %.c, build/%.o, $(SRC))

all: dirs lib/midbro bin/pasad

dirs:
	mkdir -p build bin lib

lib/midbro: $(OBJ)
	$(CC) -shared $^ -o lib/libmidbro.so $(LDFLAGS)

midbro_test:
	$(CC) test/midbro_test.c -I./includes -o bin/midbro_test -L./lib -lmidbro

bin/pasad: build/pasad.o
	$(CC) $^ $(INC) -o $@ -Llib -lmidbro -Wl,-rpath=$(shell pwd)/lib

build/%.o: src/%.c
	$(CC) $(LIBCFLAGS) $(DEBUG) $(INC) $< -o $@

bin/tests: build/fifoqueue.o build/tests.o
	$(CC) $^ -o bin/tests $(LDFLAGS)

build/tests.o: test/tests.c
	$(CC) $(CFLAGS) $(INC) $< -o $@

clean:
	rm build/* bin/*
