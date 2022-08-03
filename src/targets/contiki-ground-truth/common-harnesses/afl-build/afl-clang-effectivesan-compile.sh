#!/bin/bash
. ../contiki-setup.sh

if [[ "${EFFECTIVESAN_PATH}" = "" ]]; then
   echo "Require the path to the Effective Sanitizer root directory in EFFECTIVESAN_PATH"
   exit 1
fi 

echo
echo "Building the AFL fuzzing harness ${HARNESS_NAME} with afl-clang and effectivesan"
echo

CFLAGS+=" -mllvm -effective-blacklist=${HARNESS_PATH}/afl-build/effsan_blacklist.txt -fsanitize=effective -O2"

if [[ -z "${AFL_PATH}" ]]; then
  AFL_DONT_OPTIMIZE=1 AFL_CC=${EFFECTIVESAN_PATH}/install/bin/clang CC=afl-clang CFLAGS=${CFLAGS} LD_OVERRIDE=${CC} LDFLAGS="-fsanitize=effective" make TARGET=native ${HARNESS_NAME} WERROR=0
else
  AFL_DONT_OPTIMIZE=1 AFL_CC=${EFFECTIVESAN_PATH}/install/bin/clang CC=${AFL_PATH}/afl-clang CFLAGS=${CFLAGS} LD_OVERRIDE=${CC} LDFLAGS="-fsanitize=effective" make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.afl-clang-effectivesan

