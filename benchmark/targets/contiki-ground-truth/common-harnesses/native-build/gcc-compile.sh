#!/bin/bash
. ../contiki-setup.sh

if [ "${CC}" = "" ]; then
  CC=gcc
fi

echo
echo "Building the native fuzzing harness ${HARNESS_NAME} with ${CC}"
echo

CC=${CC} CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.native-gcc
