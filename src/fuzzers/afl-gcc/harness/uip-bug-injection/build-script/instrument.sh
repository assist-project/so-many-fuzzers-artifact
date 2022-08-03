#!/bin/sh
set -e

## Require:
#AFL_COMPANION
#AFL_PATH
#HARNESS_NAME
#WORKDIR_PATH

## compile contiki-ng with AFL_COMPANION instrumentation
echo "[+] Instrumentation:  ${AFL_COMPANION}-compile.sh"
echo "    - using           ${AFL_COMPANION}-compile.sh"
echo "    - producing:      ${HARNESS_NAME}.${AFL_COMPANION}"

cd ${HARNESS_PATH}/afl-build \
  && ./${AFL_COMPANION}-compile.sh \
  && mv bin/${HARNESS_NAME}.${AFL_COMPANION} ${WORKDIR_PATH}/bin

## and compile native-gcc for validation
cd ${HARNESS_PATH}/native-build \
  && ./gcc-compile.sh \
  && mv bin/${HARNESS_NAME}.native-gcc ${WORKDIR_PATH}/bin
