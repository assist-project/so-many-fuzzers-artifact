#!/bin/bash

make TARGET=native distclean 2>/dev/null

# https://software.intel.com/sites/landingpage/pintool/docs/71313/Pin/html/ -> Linux Compiler Requirements
if [ "$(gcc -dumpversion | cut -c1-1)" -ge 3 ] && [ $(gcc -dumpversion | cut -c1-1) -le 5 ]
then

  CC=gcc CFLAGS=${CFLAGS} make TARGET=native ${HARNESS_NAME} WERROR=0
  mkdir -p bin
  mv ${HARNESS_NAME}.native bin/${HARNESS_NAME}.native-gcc

else
  echo "Pin 2.14 is compiled by GCC 4.4.7 and is tested regularly with tools compiled with various GCC versions ranging from version 3.4.6 to version 4.7.2. (Version 5 also works.)"
fi
