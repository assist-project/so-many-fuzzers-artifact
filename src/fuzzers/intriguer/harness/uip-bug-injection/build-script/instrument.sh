#!/bin/sh
set -e

## Require:
#AFL_COMPANION
#AFL_PATH
#HARNESS_NAME
#WORKDIR_PATH

## compile contiki-ng with intriguer and ${AFL_COMPANION}-compile.sh
echo "[+] Instrumentation:  intriguer-compile.sh"
echo "    - using           ${AFL_COMPANION}-compile.sh"
echo "    - producing:      ${HARNESS_NAME}.${AFL_COMPANION}"

cd ${HARNESS_PATH}/intriguer-build \
  && ./intriguer-compile.sh \
  && mv bin/* ${WORKDIR_PATH}/bin

## and compile native-gcc for validation
cd ${HARNESS_PATH}/native-build \
  && ./gcc-compile.sh \
  && mv bin/${HARNESS_NAME}.native-gcc ${WORKDIR_PATH}/bin
