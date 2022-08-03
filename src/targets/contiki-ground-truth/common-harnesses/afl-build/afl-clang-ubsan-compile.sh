#!/bin/bash
. ../contiki-setup.sh

echo
echo "Building the AFL fuzzing harness ${HARNESS_NAME} with afl-clang and ubsan"
echo

export LDFLAGS="-fsanitize=undefined"
CFLAGS+=" -fPIE -fsanitize=undefined"

if [[ -z "${AFL_PATH}" ]]; then
  AFL_CC=clang CC=afl-clang CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0
else
  AFL_CC=clang CC=${AFL_PATH}/afl-clang CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.afl-clang-ubsan
