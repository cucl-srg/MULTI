CFLAGS += -ggdb -m32 -Wall --pedantic -Wno-format  -D_FILE_OFFSET_BITS=64
demuxer: demux.o util.o time.o dumpfiles.o
	gcc -m32 -ggdb -o $@ $^ $(LDFLAGS) -lpcap -lm

demux.o util.o time.o dumpfiles.o: demux.h config.h

demux.o util.o: proto.h
clean:
	rm -f *.o *~ demuxer
