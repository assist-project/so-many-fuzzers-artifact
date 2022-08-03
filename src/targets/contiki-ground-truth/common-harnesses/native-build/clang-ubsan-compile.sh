#!/bin/bash
unset HARNESS
HARNESS="$1"

. ../configuration/contiki-setup.sh $HARNESS

CFLAGS+=" -fsanitize=undefined,unsigned-integer-overflow -g -fno-omit-frame-pointer"

echo "Building the native fuzzing harness: $HARNESS with clang-8 and -fsanitize=undefined,unsigned-integer-overflow"
CC=clang-8 CFLAGS=$CFLAGS LD_OVERRIDE=clang-8 LDFLAGS="-fsanitize=undefined,unsigned-integer-overflow" make TARGET=native fuzzer WERROR=0

mkdir -p bin
mv $HARNESS.native bin/$HARNESS.clang-ubsan
