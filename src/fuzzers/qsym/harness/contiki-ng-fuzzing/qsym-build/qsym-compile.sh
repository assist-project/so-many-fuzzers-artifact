#!/bin/bash

## AFL instrumentation
./../afl-build/${AFL_COMPANION}-compile.sh

echo
echo "Building the fuzzer with gcc for QSYM"
echo

make TARGET=native distclean 2>/dev/null
# compile native binary (with version check)
./gcc-safe-compile.sh
