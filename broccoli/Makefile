CC=gcc
CFLAGS = -c -Wall -I/usr/local/include -I/usr/local/include -DBROCCOLI 
LDFLAGS =  -L/usr/local/lib -lbroccoli -pthread

all: midbropasad tests

midbropasad: midbropasad.o broevent.o fifoqueue.o
	$(CC) midbropasad.o broevent.o fifoqueue.o -o midbropasad $(LDFLAGS)

tests: tests.o fifoqueue.o
	$(CC) tests.o fifoqueue.o -o tests

midbropasad.o: midbropasad.c
	$(CC) $(CFLAGS) midbropasad.c

broevent.o: broevent.c
	$(CC) $(CFLAGS) broevent.c

fifoqueue.o: fifoqueue.c
	$(CC) -c -Wall fifoqueue.c

tests.o: tests.c
	$(CC) -c -Wall tests.c

clean:
	rm *.o midbropasad tests
