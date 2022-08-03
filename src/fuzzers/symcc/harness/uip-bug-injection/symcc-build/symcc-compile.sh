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
CFLAGS+=" -fPIE"

echo
echo "Building the fuzzer with SymCC"
echo
make TARGET=native distclean 2>/dev/null
if [[ -z "${SYMCC_PATH}" ]]; then
  CC=symcc CFLAGS=${CFLAGS} LD_OVERRIDE=symcc make TARGET=native ${HARNESS_NAME} WERROR=0
else
  CC=${SYMCC_PATH}/symcc_build/symcc CFLAGS=${CFLAGS} LD_OVERRIDE=${SYMCC_PATH}/symcc_build/symcc make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.symcc
