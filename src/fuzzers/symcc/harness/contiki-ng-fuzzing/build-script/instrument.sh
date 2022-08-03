#!/bin/sh
set -e

## Require:
#AFL_COMPANION
#AFL_PATH
#HARNESS_NAME
#WORKDIR_PATH

## compile contiki-ng with SymCC and AFL_COMPANION instrumentation
echo "[+] Instrumentation: symcc-compile.sh"
echo "  - using            ${AFL_COMPANION}-compile.sh"
echo "  - producing:       ${HARNESS_NAME}.${AFL_COMPANION}"

cd ${HARNESS_PATH}/symcc-build \
  && ./symcc-compile.sh \
  && mv bin/${HARNESS_NAME}.${AFL_COMPANION}  ${WORKDIR_PATH}/bin \
  && mv bin/${HARNESS_NAME}.symcc             ${WORKDIR_PATH}/bin
