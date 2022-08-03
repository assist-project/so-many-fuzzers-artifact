#!/bin/bash

if [ "${HARNESS_NAME}" = "" -o ! -f "../${HARNESS_NAME}.c" ]; then
  cat 1>&2 <<_EOF_
  Set HARNESS_NAME environment variable to select the harness (without extension).
Usage: HARNESS_NAME=filename $0
_EOF_
  exit 1
fi

## set configuration
## no configuration file if $CONTIKI_CONFIG_FILE not set
if [ "${CONTIKI_CONFIG_FILE}" != "" ]; then
  cp ../configuration/${CONTIKI_CONFIG_FILE} project-conf.h
else
  if [ -f "project-conf.h" ]; then
  mv project-conf.h not-used-project-conf.h
  fi
fi

## set contiki-ng modules
## by default the Makefile includes ../configuration/Makefile.uip-modules
if [ "${CONTIKI_MODULES_FILE}" != "" ]; then
  mv Makefile /tmp/Makefile
  sed s/Makefile.all-modules/${CONTIKI_MODULES_FILE}/g /tmp/Makefile > Makefile
fi

## AFL instrumentation
./../afl-build/${AFL_COMPANION}-compile.sh

case ${ENTRY_POINT} in
"snmp")
  CFLAGS+=" -DSNMP_ENTRYPOINT=1"
  ;;
"coap")
  CFLAGS+=" -DCOAP_ENTRYPOINT=1"
  ;;
esac

echo
echo "Building the fuzzer with gcc for QSYM"
echo
make TARGET=native distclean 2>/dev/null
# compile native binary (with version check)
./gcc-safe-compile.sh
