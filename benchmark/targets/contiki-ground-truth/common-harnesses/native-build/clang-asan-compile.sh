#!/bin/bash
unset HARNESS
HARNESS="$1"

. ../configuration/contiki-setup.sh $HARNESS

CFLAGS+=" -fsanitize=address -g -fno-omit-frame-pointer"

echo "Building the native fuzzing harness: $HARNESS with clang-8 and -fsanitize=address"
CC=clang-8 CFLAGS=$CFLAGS LD_OVERRIDE=clang-8 LDFLAGS="-fsanitize=address" make TARGET=native fuzzer WERROR=0

mkdir -p bin
mv $HARNESS.native bin/$HARNESS.clang-asan
