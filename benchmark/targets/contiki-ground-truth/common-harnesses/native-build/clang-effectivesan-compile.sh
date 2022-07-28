#!/bin/bash
. ../contiki-setup.sh

if [[ "${EFFECTIVESAN_PATH}" = "" ]]; then
   echo "Require the path to the Effective Sanitizer root directory in EFFECTIVESAN_PATH"
   exit 1
fi 

echo
echo "Building standard harness ${HARNESS_NAME} with clang and effectivesan"
echo

CFLAGS+=" -mllvm -effective-blacklist=${HARNESS_PATH}/native-build/effsan_blacklist.txt -fsanitize=effective -O2"

CC=${EFFECTIVESAN_PATH}/install/bin/clang CFLAGS=${CFLAGS} LD_OVERRIDE=${CC} LDFLAGS="-fsanitize=effective" make TARGET=native ${HARNESS_NAME} WERROR=0

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.clang-effectivesan

