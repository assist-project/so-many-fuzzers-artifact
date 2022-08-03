#!/bin/bash

## AFL instrumentation
./../afl-build/${AFL_COMPANION}-compile.sh

if [[ ${AFL_COMPANION} != "afl-gcc" ]]; then
  ## AFL-gcc instrumentation (for AFL-intriguer)
  ./../afl-build/afl-gcc-compile.sh
fi
