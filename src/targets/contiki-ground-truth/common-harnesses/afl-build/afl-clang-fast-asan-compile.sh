#!/bin/bash
. ../contiki-setup.sh

echo
echo "Building the AFL fuzzing harness ${HARNESS_NAME} with afl-clang-fast and asan"
echo

export AFL_USE_ASAN=1
export LDFLAGS="-fsanitize=address"
CFLAGS+=" -fPIE"

if [[ -z "${AFL_PATH}" ]]; then
  CC=afl-clang-fast CFLAGS=${CFLAGS} LD_OVERRIDE=afl-clang-fast make TARGET=native ${HARNESS_NAME} WERROR=0
else
  CC=${AFL_PATH}/afl-clang-fast CFLAGS=${CFLAGS} LD_OVERRIDE=${AFL_PATH}/afl-clang-fast make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.afl-clang-fast-asan
