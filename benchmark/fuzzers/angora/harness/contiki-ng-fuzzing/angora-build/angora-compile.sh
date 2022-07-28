#!/bin/bash

## AFL instrumentation
./../afl-build/${AFL_COMPANION}-compile.sh

export CC=${ANGORA_PATH}/bin/angora-clang
export LD=${ANGORA_PATH}/bin/angora-clang

echo
echo "Building the fuzzer with taint tracking support (.taint)"
echo

make TARGET=native distclean 2>/dev/null
USE_TRACK=1 CFLAGS=${CFLAGS} make V=1 WERROR=0 TARGET=native ${HARNESS_NAME} CC=${CC} LD=${LD}
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.taint

echo
echo "Building the fuzzer with light instrumentation (.fast)"
echo

make TARGET=native distclean 2>/dev/null
USE_FAST=1 CFLAGS=${CFLAGS} make V=1 WERROR=0 TARGET=native ${HARNESS_NAME} CC=${CC} LD=${LD}
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.fast
