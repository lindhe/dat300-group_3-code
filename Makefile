CC=gcc
CFLAGS = -c -Wall -I/usr/local/include -I/usr/local/include -DBROCCOLI 
LDFLAGS =  -L/usr/local/lib -lbroccoli

all: pasad

pasad: pasad.o
	$(CC) pasad.o -o pasad $(LDFLAGS) 

pasad.o: pasad.c
	$(CC) $(CFLAGS) pasad.c

clean:
	rm *.o pasad
