CC=gcc
LIBCFLAGS =-c -fPIC -DBROCCOLI
CFLAGS =-c -DBROCCOLI
INC =-I/usr/local/include -I/usr/local/include -I./includes
LDFLAGS =  -L/usr/local/lib -lbroccoli -pthread
SRC = midbro.c broevent.c fifoqueue.c
OBJ = $(patsubst %.c, build/%.o, $(SRC))

PREFIX = $(DESTDIR)/usr/local

ifneq ($(DEBUG), 1)
	CFLAGS += -O2
	CPPFLAGS += -DNDEBUG
else
	CFLAGS += -g
	CPPFLAGS += -DDEBUG
endif

.PHONY: all dirs clean install uninstall bin/tests

all: dirs lib/libmidbro.so

dirs:
	mkdir -p build bin lib

lib/libmidbro.so: $(OBJ)
	$(CC) -shared $^ -o "$@" $(LDFLAGS)

bin/midbro_test:
	$(CC) test/midbro_test.c -I./includes -o bin/midbro_test -L./lib -lmidbro

build/%.o: src/%.c
	$(CC) $(LIBCFLAGS) $(INC) $< -o $@

bin/tests: build/fifoqueue.o build/tests.o
	$(CC) $^ -o bin/tests $(LDFLAGS)

build/tests.o: test/tests.c
	$(CC) $(CFLAGS) $(INC) $< -o $@

clean:
	rm build/* bin/*

install: lib/libmidbro.so
	mkdir -p "$(PREFIX)/include"
	mkdir -p "$(PREFIX)/lib"
	mkdir -p "$(PREFIX)/share/midbro"
	cp -p includes/midbro.h "$(PREFIX)/include/"
	cp -p lib/libmidbro.so "$(PREFIX)/lib/"
	cp -p script/mid.bro "$(PREFIX)/share/midbro"

uninstall:
	rm -f "$(PREFIX)/include/midbro.h"
	rm -f "$(PREFIX)/lib/libmidbro.so"
