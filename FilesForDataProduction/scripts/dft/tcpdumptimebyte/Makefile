all: tcpdumptimebyte



tcpdumptimebyte: tcpdumptimebyte.c
	gcc -ggdb  -W -Wall -pedantic -I/usr/include/pcap -g -o tcpdumptimebyte tcpdumptimebyte.c -lpcap

clean:
	rm -f *.o tcpdumptimebyte
