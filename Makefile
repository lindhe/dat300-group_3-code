CC=gcc
CFLAGS = -c -Wall -I/usr/local/include -I/usr/local/include -DBROCCOLI 
LDFLAGS =  -L/usr/local/lib -lbroccoli

all: pasad

pasad: pasad.o fifoqueue.o
	$(CC) pasad.o fifoqueue.o -o pasad $(LDFLAGS)

pasad.o: pasad.c
	$(CC) $(CFLAGS) pasad.c

fifoqueue.o: fifoqueue.c
	$(CC) -c -Wall fifoqueue.c
clean:
	rm *.o pasad
