#!/bin/bash

. ../contiki-setup.sh

echo
echo "Building the target for HonggFuzz"
echo

make TARGET=native distclean 2>/dev/null
CFLAGS+=" -fPIE"

if [[ -z "${HONGGFUZZ_PATH}" ]]; then
  CC=hfuzz-clang CFLAGS=${CFLAGS} LD_OVERRIDE=hfuzz-clang make TARGET=native ${HARNESS_NAME} WERROR=0
else
  CC=${HONGGFUZZ_PATH}/hfuzz_cc/hfuzz-clang  CFLAGS=${CFLAGS} LD_OVERRIDE=${HONGGFUZZ_PATH}/hfuzz_cc/hfuzz-clang make TARGET=native ${HARNESS_NAME} WERROR=0
fi

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.hfuzz-clang
