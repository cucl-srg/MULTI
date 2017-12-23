/* All of the stuff which is just managing dump files. */
#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <assert.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <pcap.h>
#include "demux.h"

#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif

struct buffer_lru_entry {
	int prev;
	int next;
	unsigned used;
	void *buffer;
	struct tcpconn *tcp;
	int fd;
};

/* -1 is end of list marker */
static struct buffer_lru_entry
buffer_lru[MAX_BUFFERS];
static int
buffer_lru_head = -1,
buffer_lru_tail = -1;
static int
buffer_free_head;

struct fd_lru_entry {
	unsigned prev;
	unsigned next;
	struct buffer_lru_entry *b;
};

/* 0 is end of list marker */
static struct fd_lru_entry
fd_lru[MAX_FDS];
static unsigned
fd_lru_head,
fd_lru_tail;

static void flush_buffer(struct tcpconn *tcp);

static void
unlink_buffer_lru(struct tcpconn *tcp)
{
	assert(tcp->buffer_id >= 0);
	assert(tcp->buffer_id < MAX_BUFFERS);
	assert(buffer_lru[tcp->buffer_id].tcp == tcp);
	if (buffer_lru[tcp->buffer_id].prev != -1)
		buffer_lru[buffer_lru[tcp->buffer_id].prev].next =
			buffer_lru[tcp->buffer_id].next;
	if (buffer_lru[tcp->buffer_id].next != -1)
		buffer_lru[buffer_lru[tcp->buffer_id].next].prev =
			buffer_lru[tcp->buffer_id].prev;
	if (buffer_lru_head == tcp->buffer_id)
		buffer_lru_head = buffer_lru[tcp->buffer_id].next;
	if (buffer_lru_tail == tcp->buffer_id)
		buffer_lru_tail = buffer_lru[tcp->buffer_id].prev;
	buffer_lru[tcp->buffer_id].next =
		buffer_lru[tcp->buffer_id].prev = 0;
}

void
release_buffer(struct tcpconn *tcp)
{
	struct buffer_lru_entry *b;
	int id;

	id = tcp->buffer_id;
	assert(tcp->buffer_id >= 0);
	assert(tcp->buffer_id < MAX_BUFFERS);
	b = &buffer_lru[id];
	flush_buffer(tcp);
	assert(id == tcp->buffer_id);
	assert(b->tcp == tcp);
	assert(b->used == 0);
	unlink_buffer_lru(tcp);
	tcp->buffer_id = -1;
	b->tcp = NULL;
	b->prev = -1;
	b->next = buffer_free_head;
	buffer_free_head = id;
	stats.gced_buffers++;
}

static void
touch_buffer_lru(struct tcpconn *tcp)
{
	assert(tcp->buffer_id >= 0);
	assert(tcp->buffer_id < MAX_BUFFERS);
	assert(buffer_lru[tcp->buffer_id].tcp == tcp);
	if (buffer_lru_head != -1)
		buffer_lru[buffer_lru_head].prev = tcp->buffer_id;
	buffer_lru[tcp->buffer_id].prev = -1;
	buffer_lru[tcp->buffer_id].next = buffer_lru_head;
	buffer_lru_head = tcp->buffer_id;
	if (buffer_lru_tail == -1)
		buffer_lru_tail = tcp->buffer_id;
}

static void
touch_fd_lru(struct buffer_lru_entry *b)
{
	assert(b->fd != 0);
	assert(b->fd < MAX_FDS);
	assert(fd_lru[b->fd].b == b);
	assert(fd_lru[fd_lru_head].prev == 0);
	fd_lru[fd_lru_head].prev = b->fd;
	fd_lru[b->fd].next = fd_lru_head;
	fd_lru[b->fd].prev = 0;
	if (fd_lru_head)
		assert(fd_lru_tail);
	if (fd_lru_tail)
		assert(fd_lru_head);
	fd_lru_head = b->fd;
	if (!fd_lru_tail)
		fd_lru_tail = b->fd;
}

static void
unlink_fd_lru(struct buffer_lru_entry *b)
{
	assert(b->fd != 0);
	assert(b->fd < MAX_FDS);
	assert(fd_lru[b->fd].b == b);
	assert(fd_lru_tail);
	assert(fd_lru_head);
	fd_lru[fd_lru[b->fd].next].prev = fd_lru[b->fd].prev;
	fd_lru[fd_lru[b->fd].prev].next = fd_lru[b->fd].next;
	if (fd_lru_head == b->fd)
		fd_lru_head = fd_lru[b->fd].next;
	if (fd_lru_tail == b->fd)
		fd_lru_tail = fd_lru[b->fd].prev;
	if (!fd_lru_head) {
		assert(!fd_lru_tail);
		assert(!fd_lru[b->fd].next);
		assert(!fd_lru[b->fd].prev);
	}
	if (!fd_lru_tail) {
		assert(!fd_lru_head);
	}
	fd_lru[b->fd].next = fd_lru[b->fd].prev = 0;
}

static void
replenish_fd(struct tcpconn *tcp, struct buffer_lru_entry *b)
{
	static char fname[4096];
	int x, y;
	struct pcap_file_header pfh;
	static FILE *sense_file;

	x = sprintf(fname, "%s/%P", output_prefix, tcp);
	y = open(fname, O_APPEND | O_WRONLY);
	if (y < 0 && (errno == ENFILE || errno == EMFILE)) {
		collect_fds();
		y = open(fname, O_APPEND | O_WRONLY);
	}
	if (y >= 0) {
		b->fd = y;
		if (!tcp->has_file)
			errx(1, "%s already exists", fname);
		fd_lru[b->fd].b = b;
		touch_fd_lru(b);
		stats.fds_used++;
		assert(b->fd < MAX_FDS);
		assert(b->fd != 0);
		return;
	}
	if (tcp->has_file)
		err(1, "cannot re-open %s!", fname);

	if (tcp->sid.protocol == 6) {
		if (!sense_file) {
			collect_fds();
			sense_file = fopen("senses", "a");
			if (!sense_file)
				err(1, "openning sense file");
		}
		if (tcp->flow[0].c2s)
			fprintf(sense_file, "%P client/server\n",
				tcp);
		else if (tcp->flow[1].c2s)
			fprintf(sense_file, "%P server/client\n",
				tcp);
		else
			fprintf(sense_file, "%P unknown\n",
				tcp);
	}

	fname[x] = '!';
	while (x > 0) {
		while (x > 0 && fname[x] != '/')
			x--;
		if (x == 0)
			break;
		fname[x] = 0;
#if 0
		/* This turns out to not actually be an
		 * optimisation */
		if (mkdir(fname, 0777) >= 0 || errno == EEXIST)
			break;
#endif
	}
	while (fname[x] != '!' && fname[x])
		x++;
	if (fname[x] != '!')
		fname[x] = '/';
	while (fname[x] != '!' && fname[x])
		x++;
	while (fname[x] != '!') {
		if (mkdir(fname, 0777) < 0 && errno != EEXIST)
			err(1, "making directory %s", fname);
		fname[x] = '/';
		while (fname[x] != '!' && fname[x])
			x++;
	}
	fname[x] = 0;
	y = open(fname, O_CREAT | O_WRONLY | O_EXCL, 0666);
	if (y < 0 && (errno == EMFILE || errno == ENFILE)) {
		collect_fds();
		y = open(fname, O_CREAT | O_WRONLY | O_EXCL, 0666);
	}
	if (y < 0)
		err(1, "openning %s", fname);
	b->fd = y;
	assert(b->fd != 0);

	assert(b->fd < MAX_FDS);
	stats.fds_used++;

	tcp->has_file = 1;

	fd_lru[b->fd].b = b;
	touch_fd_lru(b);

	pfh.magic = 0xa1b2c3d4;
	pfh.version_major = 2;
	pfh.version_minor = 4;
	pfh.thiszone = 0;
	pfh.sigfigs = 6;
	pfh.snaplen = 65535;
	pfh.linktype = link_type;
	if (write(b->fd, &pfh, sizeof(pfh)) != sizeof(pfh))
		err(1, "writing to %s", fname);

	assert(b->fd != 0);
}

static void
flush_buffer(struct tcpconn *tcp)
{
	int r;
	struct buffer_lru_entry *b = &buffer_lru[tcp->buffer_id];

	if (tcp->buffer_id == -1)
		return;
	if (b->used == 0)
		return;
	stats.fd_requests++;
	if (b->fd == 0) {
		replenish_fd(tcp, b);
	} else {
		stats.fd_hits++;
		unlink_fd_lru(b);
		touch_fd_lru(b);
	}
	assert(b->fd != 0);
	r = write(b->fd, b->buffer, b->used);
	if (r != b->used)
		abort();
	b->used = 0;
}

static void
get_fresh_buffer(struct tcpconn *tcp)
{
	int res;
	struct buffer_lru_entry *b;

	if (buffer_free_head != -1) {
		res = buffer_free_head;
		buffer_free_head = buffer_lru[buffer_free_head].next;
		if (buffer_free_head != -1)
			buffer_lru[buffer_free_head].prev = -1;
	} else {
		res = buffer_lru_tail;
		buffer_lru_tail = buffer_lru[buffer_lru_tail].prev;
	}
	b = &buffer_lru[res];
	if (b->used)
		flush_buffer(b->tcp);
	assert(b->used == 0);
	if (b->tcp) {
		b->tcp->buffer_id = -1;
		stats.gced_buffers++;
	}
	if (!b->buffer)
		b->buffer = malloc(PER_CONN_BUFFER);
	b->tcp = tcp;
	tcp->buffer_id = res;
	touch_buffer_lru(tcp);
}

static void
replenish_buffer(struct tcpconn *tcp)
{
	if (tcp->buffer_id != -1) {
		flush_buffer(tcp);
	} else {
		get_fresh_buffer(tcp);
	}
}

static void
write_flow_bytes(struct tcpconn *tcp, const void *buf, unsigned size)
{
	unsigned long written_so_far;
	unsigned long write_this_pass;
	struct buffer_lru_entry *b;

	if (output_prefix[0] == 0)
		return;
	written_so_far = 0;
	stats.buffer_requests++;
	if (tcp->buffer_id == -1)
		replenish_buffer(tcp);
	else
		stats.buffer_hits++;
	b = &buffer_lru[tcp->buffer_id];
	while (written_so_far < size) {
		if (b->used == PER_CONN_BUFFER) {
			stats.buffer_full_flushes++;
			replenish_buffer(tcp);
		}
		write_this_pass = size - written_so_far;
		if (write_this_pass > PER_CONN_BUFFER - b->used)
			write_this_pass = PER_CONN_BUFFER - b->used;
		memcpy(b->buffer + b->used,
		       buf + written_so_far,
		       write_this_pass);
		written_so_far += write_this_pass;
		b->used += write_this_pass;
	}
	unlink_buffer_lru(tcp);
	touch_buffer_lru(tcp);
}

static void
dump_flow_packet(struct tcpconn *tcp, struct packet *p)
{
	struct pcap_pkthdr ph;
	ph.ts = timestamp_to_timeval(p->ts);
	ph.caplen = p->len;
	ph.len = p->len;
	write_flow_bytes(tcp, &ph, sizeof(ph));
	write_flow_bytes(tcp, p->payload, p->len);
}

void
dump_flow_datagram(struct tcpconn *tcp, struct datagram *dg)
{
	struct packet *p;
	for (p = dg->head_packet; p; p = p->next_time)
		dump_flow_packet(tcp, p);
}

void
test_func(char *buf)  
{
sprintf(buf,"%s/ign_packets",output_prefix); 
}
// N - fucntion test  


void
dump_unhandled_packet(struct packet *p)
{
	static FILE *f;
	struct pcap_pkthdr ph;
	struct pcap_file_header pfh;
	if (!f) {
		char buf[4096];
		test_func(buf);
		//sprintf(buf, "%s/ign_packets", output_prefix);
		collect_fds();
		f = fopen(buf, "ab");
		if (!f)
			err(1, "openning out/ign_packets");
		pfh.magic = 0xa1b2c3d4;
		pfh.version_major = 2;
		pfh.version_minor = 2;
		pfh.thiszone = 0;
		pfh.sigfigs = 6;
		pfh.snaplen = 65535;
		pfh.linktype = link_type;
		fwrite(&pfh, sizeof(pfh), 1, f);

	}
	ph.ts = timestamp_to_timeval(p->ts);
	ph.caplen = p->len;
	ph.len = p->len;
	fwrite(&ph, sizeof(ph), 1, f);
	fwrite(p->payload, p->len, 1, f);
}



void
dump_unhandled_datagram(struct datagram *dg)
{
	struct packet *p;
	for (p = dg->head_packet; p; p = p->next_time)
		dump_unhandled_packet(p);
}

static void
close_connection_fd(struct buffer_lru_entry *b)
{
	assert(b->fd != 0);
	unlink_fd_lru(b);
	fd_lru[b->fd].b = NULL;
	close(b->fd);
	b->fd = 0;
	stats.fds_used--;
	stats.gced_fds++;
}

void
collect_fds(void)
{
	struct buffer_lru_entry *b;
	int fd;
	if (!fd_lru_tail) {
		warnx("tried to collect file descriptors, but nothing was available");
		return; /* Uh oh  !! N - need to undo do this later. */
	}
	printf("fd_tail:%i here i am",fd_lru_tail); 
	fd = fd_lru_tail;
	b = fd_lru[fd].b;
	assert(b->fd == fd);
	if (b->tcp)
		flush_buffer(b->tcp);
	close_connection_fd(b);
}


void
setup_buffers(void)
{
	int x;
	for (x = 0; x < MAX_BUFFERS - 1; x++) {
		buffer_lru[x].next = x + 1;
		buffer_lru[x+1].prev = x;
	}
	buffer_lru[0].prev = -1;
	buffer_lru[x].next = -1;
}

teardown_buffers(void)
{
	int x;
	struct tcpconn *tcp;
	for (x = 0; x < MAX_BUFFERS; x++) {
		tcp = buffer_lru[x].tcp;
		if (!tcp)
			continue;
		release_buffer(tcp);
	}
}

static void
sanity_check_fds(void)
{
	int x;
	int cntr = 0;
	for (x = 1; x < MAX_FDS; x++) {
		if (!fd_lru[x].b)
			continue;
		if (fd_lru[x].next) {
			assert(fd_lru[fd_lru[x].next].b);
			assert(fd_lru[fd_lru[x].next].prev == x);
		}
		if (fd_lru[x].prev) {
			assert(fd_lru[fd_lru[x].prev].b);
			assert(fd_lru[fd_lru[x].prev].next == x);
		}
		assert(fd_lru[x].b->fd == x);
		cntr++;
	}
	assert(cntr == stats.fds_used);
	if (fd_lru_head) {
		assert(fd_lru[fd_lru_head].prev == 0);
		if (cntr != 1)
			assert(fd_lru[fd_lru_head].next);
		assert(fd_lru[fd_lru_head].b);
		assert(fd_lru_tail);
	}
	if (fd_lru_tail) {
		assert(fd_lru_head);
		assert(fd_lru[fd_lru_tail].b);
		assert(fd_lru[fd_lru_tail].next == 0);
		if (cntr != 1)
			assert(fd_lru[fd_lru_tail].prev);
	}
	if (cntr == 1)
		assert(fd_lru_tail == fd_lru_head);
	if (cntr) {
		assert(fd_lru_head);
		assert(fd_lru_tail);
	} else {
		assert(!fd_lru_head);
		assert(!fd_lru_tail);
	}
	for (x = fd_lru_head; x && cntr; x = fd_lru[x].next, cntr--)
		;
	assert(!x);
	assert(!cntr);
}

static void
sanity_check_buffers(void)
{
	int x;
	int cntr = 0;
	for (x = 0; x < MAX_BUFFERS; x++) {
		if (buffer_lru[x].next != -1) {
			assert(buffer_lru[buffer_lru[x].next].prev == x);
		}
		if (buffer_lru[x].prev != -1) {
			assert(buffer_lru[buffer_lru[x].prev].next == x);
		}
		if (buffer_lru[x].tcp) {
			if (buffer_lru[x].next == -1) {
				assert(x == buffer_lru_tail);
			} else {
				assert(x != buffer_lru_tail);
				assert(buffer_lru[buffer_lru[x].next].tcp);
			}
			if (buffer_lru[x].prev == -1) {
				assert(x == buffer_lru_head);
			} else {
				assert(x != buffer_lru_head);
				assert(buffer_lru[buffer_lru[x].prev].tcp);
			}
			cntr++;
		} else {
			if (buffer_lru[x].next != -1) {
				assert(!buffer_lru[buffer_lru[x].next].tcp);
			}
			if (buffer_lru[x].prev == -1) {
				assert(x == buffer_free_head);
			} else {
				assert(x != buffer_free_head);
				assert(!buffer_lru[buffer_lru[x].prev].tcp);
			}
			assert(!buffer_lru[x].used);
		}
	}
	if (cntr) {
		assert(buffer_lru_head != -1);
		assert(buffer_lru_tail != -1);
	} else {
		assert(buffer_lru_head == -1);
		assert(buffer_lru_tail == -1);
	}
	if (cntr == MAX_BUFFERS) {
		assert(buffer_free_head == -1);
	} else {
		assert(buffer_free_head != -1);
	}
}

void
sanity_check_dumpfiles(void)
{
	sanity_check_fds();
	sanity_check_buffers();
}

#define MAP_SIZE (PAGE_SIZE * 1024)

void
process_file(const char *fname, const char *filter,
	     void (*cb)(const struct pcap_pkthdr *hdr,
			const unsigned char *data))
{
	struct bpf_program bpf;
	int fd = -1;
	void *map = MAP_FAILED;
	unsigned long long map_avail;
	unsigned long long map_offset;
	unsigned long long len, processed;
	struct pcap_file_header *pfh;
	unsigned long long mmap_size;
	int have_filter = 0;
	struct pcap_pkthdr *pkt_hdr;
	
	fd = open(fname, O_RDONLY); 

	if (fd < 0) {
		fprintf(logfile, "cannot open %s (%s)\n", fname,
			strerror(errno));
		return;
	}
	len = lseek(fd, 0, SEEK_END);

	if (len < sizeof(struct pcap_file_header)) {
		fprintf(logfile, "%s is too small", fname);
		close(fd);
		return;
	}

	map_avail = len;
	if (map_avail > MAP_SIZE)
		map_avail = MAP_SIZE;
	printf("page_size:%i \n",PAGE_SIZE);
	mmap_size = (map_avail + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);

	printf("~PAGE_SIZE-1:%d, map_avail:%u, mmap_size:%u,\n ", ~(PAGE_SIZE-1), map_avail, mmap_size); 

	map = mmap(NULL, mmap_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (map == MAP_FAILED) {
		fprintf(logfile, "cannot map %s (%s)\n", fname,
			strerror(errno));
		close(fd);
		return;
	}
	madvise(map, mmap_size, MADV_SEQUENTIAL);

	pfh = map;
	if (pfh->magic != 0xa1b2c3d4) {
		fprintf(logfile, "%s is not a pcap dump file\n", fname);
		goto out;
	}
	if (pfh->version_major != 2 || pfh->version_minor != 2) {
		fprintf(logfile, "Only pcap version 2.2 is supported; %s is version %d.%d.\n",
			fname, pfh->version_major, pfh->version_minor);
	}

	if (filter) {
		if (pcap_compile_nopcap(pfh->snaplen,
					pfh->linktype,
					&bpf,
					(char *)filter,
					1, 0) < 0)
			errx(1, "cannot compile %s", filter);
		have_filter = 1;
	}
	link_type = pfh->linktype;

	map_offset = 0;
	processed = sizeof(*pfh);
	while (processed < len) {
		pkt_hdr = map + (processed - map_offset);
		if (processed - map_offset >= mmap_size - PAGE_SIZE) {

			munmap(map, mmap_size);

			//printf("mmapsize:%d, map_offset:%d, processed - map_offset:%d, mmapsize - PAGE_SIZE:%d", mmap_size, map_offset, processed - map_offset, mmap_size - PAGE_SIZE);
			//checking vars	

			if (mmap_size - PAGE_SIZE == 0){
				break;
			}

			map_offset += mmap_size - PAGE_SIZE;

			assert(processed >= map_offset);

			map_avail = len - processed;
			if (map_avail > MAP_SIZE)
				map_avail = MAP_SIZE;

			mmap_size=(map_avail+PAGE_SIZE - 1) & ~(PAGE_SIZE - 1 );
			map = mmap(NULL, mmap_size, PROT_READ, MAP_PRIVATE, fd,
				   map_offset);
			if (map == MAP_FAILED) {
				fprintf(logfile, "cannot map %s (%s)\n", fname,
					strerror(errno));
				exit(1);
			}
			madvise(map, mmap_size, MADV_SEQUENTIAL);
			continue;
		}
		cb(pkt_hdr, (void *)(pkt_hdr + 1));
		processed += sizeof(*pkt_hdr) + pkt_hdr->caplen;
	}

 out:
	if (have_filter)
		pcap_freecode(&bpf);
	if (fd >= 0)
		close(fd);
	if (map != MAP_FAILED)
		munmap(map, mmap_size);
}

