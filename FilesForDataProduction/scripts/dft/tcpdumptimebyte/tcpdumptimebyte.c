/*
Copyright (C) 2003  Andrew Moore <andrew.moore@cl.cam.ac.uk>

based upon tcprmdup by Christian Kreibich <christian.kreibich@cl.cam.ac.uk>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies of the Software and its documentation and acknowledgment shall be
given in the documentation and software packages that this Software was
used.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


#include <sys/types.h>
#include <sys/stat.h>
#include <getopt.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef MAXPATHLEN
#define MAXPATHLEN 4096
#endif

#ifndef BIG_SPACE
#define BIG_SPACE 16000
#endif

/* include path is fixed through Makefile if it's a pcap/pcap.h system: */
#include <pcap.h>

typedef struct pcap_packet_info
{
  u_int          caplen;
  u_char        *data;    /* always pcap file snaplen */
} PacketInfo;


struct pcap_cb_data
{
  pcap_t        *pcap;


  char          *tcpdump_input;
  char          *tcpdump_output;
  char          *tcpdump_master;

/*  PacketInfo    *history;
  int            hist_slots;
  int            hist_current;*/

  u_int          total;
  u_int          dropped;
};


static char pcap_errbuf[PCAP_ERRBUF_SIZE];

u_int    caplen_master; 
u_char  *cb_data_master; /* stuck in global spac
			  so the pcap_loop can use it */



static void
trd_print_usage_exit(const char *progname)
{  
  fprintf(stderr,"USAGE: %s <input tracefile>\n\n"
	 "Takes and dumps a stream of timestamp and (wire)bytes\n",
	 progname);

  exit(0);
}


static void 
trd_pcap_cb(u_char *user,
	    const struct pcap_pkthdr *pkthdr,
	    const u_char *packet)
{
  struct pcap_cb_data *cb_data = (struct pcap_cb_data *) user;

  fprintf(stdout,"%u.%06u %d\n",(uint) pkthdr->ts.tv_sec, 
								(uint) pkthdr->ts.tv_usec,pkthdr->len);

}


int 
main(int argc, char** argv)
{
  struct pcap_cb_data cb_data;




  if (argc < 2)
    trd_print_usage_exit(argv[0]);	  

  cb_data.tcpdump_input = argv[optind];
  
  if (!cb_data.tcpdump_master)
    {
      fprintf(stderr,"No master file provided\n");
      trd_print_usage_exit(argv[0]);	  
      exit(-1);
    }


  



  if ((cb_data.pcap = pcap_open_offline(cb_data.tcpdump_input, pcap_errbuf)) == NULL)
    {
      fprintf(stderr,"Could not open source trace file %s\n", cb_data.tcpdump_input);
      exit(-1);
    }

  pcap_loop(cb_data.pcap, -1, trd_pcap_cb, (u_char*) &cb_data);
  
  /* At last, clean up. */
  pcap_close(cb_data.pcap);  

  /* Mask any error codes pcap_loop may have left over. */
  exit(0);
}
