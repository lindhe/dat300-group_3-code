CC=gcc
CFLAGS = -c -Wall -I/usr/local/include -I/usr/local/include -DBROCCOLI 
LDFLAGS =  -L/usr/local/lib -lbroccoli

all: broevent

broevent: broevent.o fifoqueue.o
	$(CC) broevent.o fifoqueue.o -o broevent $(LDFLAGS)

broevent.o: broevent.c
	$(CC) $(CFLAGS) broevent.c

fifoqueue.o: fifoqueue.c
	$(CC) -c -Wall fifoqueue.c
clean:
	rm *.o broevent
