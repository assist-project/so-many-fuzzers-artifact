#!/bin/bash

if [ "${HARNESS_NAME}" = "" -o ! -f "../${HARNESS_NAME}.c" ]; then
  cat 1>&2 <<_EOF_
  Set HARNESS_NAME environment variable to select the harness (without extension).
Usage: HARNESS_NAME=filename $0
_EOF_
  exit 1
fi

## AFL instrumentation
./../afl-build/${AFL_COMPANION}-compile.sh

if [[ ${AFL_COMPANION} != "afl-gcc" ]]; then
  ## AFL-gcc instrumentation (for AFL-intriguer)
  ./../afl-build/afl-gcc-compile.sh
fi
