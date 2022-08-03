#!/bin/bash
## run from one of the build folders

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
  sed "s|include .*-modules|include ../configuration/${CONTIKI_MODULES_FILE}|g" /tmp/Makefile > Makefile
fi

make TARGET=native distclean 2>/dev/null
case ${ENTRY_POINT} in
"coap")
  export CFLAGS+=" -DCOAP_ENTRYPOINT=1"
  ;;
"snmp")
  export CFLAGS+=" -DSNMP_ENTRYPOINT=1"
  ;;
esac

## MAKE_ARGS: extra arguments for Makefile
### such that MAKE_ROUTING=MAKE_ROUTING_RPL_CLASSIC for fuzzing RPL_CLASSIC instead of RPL_LITE
if [ "${MAKE_ARGS}" != "" ]; then
  export "${MAKE_ARGS}"
fi
