#!/bin/bash
. ../contiki-setup.sh

echo
echo "Building the AFL fuzzing harness ${HARNESS_NAME} with afl-gcc and asan"
echo

export AFL_USE_ASAN=1
export LDFLAGS="-fsanitize=address"
CFLAGS+=" -fPIE"

if [[ -z "${AFL_PATH}" ]]; then
  AFL_CC=gcc CC=afl-gcc CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0
else
  AFL_CC=gcc CC=${AFL_PATH}/afl-gcc CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.afl-gcc-asan
