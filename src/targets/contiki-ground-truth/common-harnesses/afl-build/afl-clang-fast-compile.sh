#!/bin/bash
. ../contiki-setup.sh

echo
echo "Building the AFL fuzzing harness ${HARNESS_NAME} with afl-clang-fast"
echo

CFLAGS+=" -fPIE"

if [[ -z "${AFL_PATH}" ]]; then
  AFL_CC=clang CC=afl-clang-fast CFLAGS=${CFLAGS} LD_OVERRIDE=afl-clang-fast make TARGET=native ${HARNESS_NAME} WERROR=0
else
  AFL_CC=clang CC=${AFL_PATH}/afl-clang-fast CFLAGS=${CFLAGS} LD_OVERRIDE=${AFL_PATH}/afl-clang-fast make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.afl-clang-fast
