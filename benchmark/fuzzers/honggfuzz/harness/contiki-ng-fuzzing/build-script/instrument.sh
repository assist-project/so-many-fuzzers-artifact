#!/bin/sh
set -e

## Require:
#HONGGFUZZ_PATH
#HARNESS_NAME
#WORKDIR_PATH

## compile contiki-ng with hfuzz-clang instrumentation
echo "[+] Instrumentation:  hfuzz-clang-compile.sh"
echo "    - producing:      ${HARNESS_NAME}.hfuzz-clang"

cd ${HARNESS_PATH}/hfuzz-build \
  && ./hfuzz-clang-compile.sh \
  && mv bin/${HARNESS_NAME}.hfuzz-clang ${WORKDIR_PATH}/bin
