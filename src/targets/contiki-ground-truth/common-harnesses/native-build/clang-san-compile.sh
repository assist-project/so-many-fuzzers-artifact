#!/bin/bash
. ../contiki-setup.sh

clang_version=$(clang -dumpversion 2>/dev/null | cut -d'.' -f1-1)
if [[ -z "${clang_version}" || ${clang_version} -lt 8 ]];
then
    CC=clang-8
else
    CC=clang
fi

echo
echo "Building the native fuzzing harness ${HARNESS_NAME} with ${CC} and asan/ubsan"
echo

CFLAGS+=" -fsanitize=undefined,address -g -fno-omit-frame-pointer"

CC=${CC} CFLAGS=${CFLAGS} LD_OVERRIDE=${CC} LDFLAGS="-fsanitize=undefined,address" make TARGET=native ${HARNESS_NAME} WERROR=0

mkdir -p bin
mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.san
