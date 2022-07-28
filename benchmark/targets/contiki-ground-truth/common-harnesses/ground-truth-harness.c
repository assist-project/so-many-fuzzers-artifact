/*
 * Copyright (c) 2019, RISE Research Institutes of Sweden AB
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Institute nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE INSTITUTE AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**
 * \file
 *   Fuzzing harness for various protocol implementations in Contiki-NG.
 * \author
 *   Nicolas Tsiftes <nicolas.tsiftes@ri.se>
 */

#include "contiki.h"

/* Standard C and POSIX headers. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

/* Contiki-NG headers required for fuzzing the network stack. */
#include <net/ipv6/uip.h>
#include <net/ipv6/uip-icmp6.h>
#include <net/ipv6/uiplib.h>
#include <net/netstack.h>
#include <net/packetbuf.h>
#include <net/ipv6/sicslowpan.h>

#if COAP_ENTRYPOINT
#include <net/app-layer/coap/coap.h>
#include <net/app-layer/coap/coap-engine.h>
#endif

#if SNMP_ENTRYPOINT
#include <net/app-layer/snmp/snmp.h>
#include <net/app-layer/snmp/snmp-engine.h>
#endif

/* Log configuration. */
#include "sys/log.h"
#define LOG_MODULE "Fuzzer"
#define LOG_LEVEL LOG_LEVEL_INFO

#define ENTRY_POINT_DEFAULT "uip"
#define FUZZ_FILE_DEFAULT "fuzzing-input"
#define FUZZ_BUFFER_SIZE 2000

#define FUZZ_COAP_ENDPOINT "fdfd::100"
#define FUZZ_COAP_PORT 8293

/* When persitent mode is set, the fuzzer will run multiple fuzzing tests within a process.
   Note that the code must be compiled with afl-clang-fast. */
#define FUZZ_PERSISTENT_MODE 0

typedef bool (*fuzzer_function_t)(char *, int);

extern int contiki_argc;
extern char **contiki_argv;

/*---------------------------------------------------------------------------*/
PROCESS(fuzzing_process, "Fuzzing process");
AUTOSTART_PROCESSES(&fuzzing_process);
/*---------------------------------------------------------------------------*/
static int
read_fuzzing_data(const char *filename, char *buf, int max_len)
{
  int fd;
  int len;

  /* Read fuzzing input. */
  fd = open(filename, O_RDONLY);
  if(fd < 0) {
    LOG_ERR("open: %s\n", strerror(errno));
    return -1;
  }

  len = read(fd, buf, max_len);
  if(len < 0) {
    LOG_ERR("read: %s\n", strerror(errno));
    close(fd);
    return -1;
  }

  close(fd);
  return len;
}
#if COAP_ENTRYPOINT
/*---------------------------------------------------------------------------*/
static bool
inject_coap_packet(char *data, int len)
{
  static coap_endpoint_t end_point;

  uiplib_ipaddrconv(FUZZ_COAP_ENDPOINT, &end_point.ipaddr);
  end_point.port = FUZZ_COAP_PORT;
  end_point.secure = 0;

  coap_endpoint_print(&end_point);

  coap_receive(&end_point, (uint8_t *)data, len);

  return true;
}
#endif
/*---------------------------------------------------------------------------*/
static bool
inject_icmpv6_packet(char *data, int len)
{
  if(len > sizeof(uip_buf)) {
    LOG_DBG("Adjusting the input length from %d to %d to fit the uIP buffer\n",
            len, (int)sizeof(uip_buf));
    len = sizeof(uip_buf);
  }

  uip_len = len;

  /* Fill uIP buffer with fuzzing data. */
  memcpy(uip_buf, data, len);

  uip_icmp6_input(UIP_ICMP_BUF->type, UIP_ICMP_BUF->icode);

  return true;
}
/*---------------------------------------------------------------------------*/
static bool
inject_sicslowpan_packet(char *data, int len)
{
  packetbuf_copyfrom(data, len);

  NETSTACK_NETWORK.input();
  NETSTACK_FRAMER.parse();

  sicslowpan_driver.input();

  return true;
}
/*---------------------------------------------------------------------------*/
#if SNMP_ENTRYPOINT
static bool
inject_snmp_packet(char *data, int len)
{
  snmp_packet_t snmp_packet;
  uint8_t out_buf[UIP_BUFSIZE];

  snmp_packet.in = (uint8_t *)data;
  snmp_packet.used = len;

  snmp_packet.max = UIP_BUFSIZE - UIP_IPUDPH_LEN;
  snmp_packet.out = out_buf + snmp_packet.max;

  return snmp_engine(&snmp_packet) != 0;
}
#endif /* SNMP_ENTRYPOINT */
/*---------------------------------------------------------------------------*/
static bool
inject_uip_packet(char *data, int len)
{
  if(len > sizeof(uip_buf)) {
    LOG_DBG("Adjusting the input length from %d to %d to fit the uIP buffer\n",
            len, (int)sizeof(uip_buf));
    len = sizeof(uip_buf);
  }

  uip_len = len;

  /* Fill uIP buffer with fuzzing data. */
  memcpy(uip_buf, data, len);

  uip_input();

  return true;
}
/*---------------------------------------------------------------------------*/
fuzzer_function_t
select_fuzzer(const char *protocol_name)
{
  struct proto_mapper {
    const char *protocol_name;
    fuzzer_function_t function;
  };
  struct proto_mapper map[] = {
#if COAP_ENTRYPOINT
    {"coap", inject_coap_packet},
#endif
#if DNS_ENTRYPOINT
    {"dns", inject_dns_packet},
#endif
    {"icmpv6", inject_icmpv6_packet},
    {"sicslowpan", inject_sicslowpan_packet},
#if SNMP_ENTRYPOINT
    {"snmp", inject_snmp_packet},
#endif
    {"uip", inject_uip_packet}
  };
  int i;

  if(protocol_name == NULL) {
    return NULL;
  }

  for(i = 0; i < sizeof(map) / sizeof(map[0]); i++) {
    if(strcasecmp(protocol_name, map[i].protocol_name) == 0) {
      return map[i].function;
    }
  }

  return NULL;
}
/*---------------------------------------------------------------------------*/
PROCESS_THREAD(fuzzing_process, ev, data)
{
  static char file_buf[FUZZ_BUFFER_SIZE];
  static int len;
  static const char *filename;
  static const char *protocol;
  static fuzzer_function_t fuzzer;

  PROCESS_BEGIN();

  if(contiki_argc > 1) {
    filename = contiki_argv[1];
  } else {
    filename = getenv("FUZZ_FILE");
    if(filename == NULL) {
      filename = FUZZ_FILE_DEFAULT;
    }
  }

  protocol = getenv("ENTRY_POINT");
  if(protocol == NULL) {
    protocol = ENTRY_POINT_DEFAULT;
  }

  fuzzer = select_fuzzer(protocol);
  if(fuzzer == NULL) {
    LOG_ERR("unsupported protocol: \"%s\"\n",
            protocol == NULL ? "<null>" : protocol);
    exit(EXIT_FAILURE);
  }

  LOG_INFO("Fuzzing protocol %s with input from file \"%s\"\n", protocol, filename);

  len = read_fuzzing_data(filename, file_buf, FUZZ_BUFFER_SIZE);
  if(len < 0) {
    /* Failed to read the fuzzing data. */
    exit(EXIT_FAILURE);
  }

  LOG_INFO("Injecting a packet of %d bytes\n", len);

  if(fuzzer(file_buf, len) == false) {
    exit(EXIT_FAILURE);
  }

  exit(EXIT_SUCCESS);

  PROCESS_END();
}
/*---------------------------------------------------------------------------*/
