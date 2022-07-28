#!/bin/bash

if [ "${HARNESS_NAME}" = "" -o ! -f "../${HARNESS_NAME}.c" ]; then
  cat 1>&2 <<_EOF_
  Set HARNESS_NAME environment variable to select the harness (without extension).
Usage: HARNESS_NAME=filename $0
_EOF_
  exit 1
fi

cp ../${HARNESS_NAME}.c .

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
## by default the Makefile includes ../configuration/Makefile.all-modules
if [ "${CONTIKI_MODULES_FILE}" != "" ]; then
  mv Makefile /tmp/Makefile
  sed s/Makefile.all-modules/${CONTIKI_MODULES_FILE}/g /tmp/Makefile > Makefile
fi

case ${ENTRY_POINT} in
"snmp")
  CFLAGS+=" -DSNMP_ENTRYPOINT=1"
  ;;
"coap")
  CFLAGS+=" -DCOAP_ENTRYPOINT=1"
  ;;
esac

make TARGET=native distclean 2>/dev/null
# https://software.intel.com/sites/landingpage/pintool/docs/71313/Pin/html/ -> Linux Compiler Requirements
if [ "$(gcc -dumpversion | cut -c1-1)" -ge 3 ] && [ $(gcc -dumpversion | cut -c1-1) -le 5 ]
then
  CC=gcc CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0

  mkdir -p bin
  mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.native-gcc
else
  echo "Pin 2.14 is compiled by GCC 4.4.7 and is tested regularly with tools compiled with various GCC versions ranging from version 3.4.6 to version 4.7.2. (Version 5 also works.)"
fi
