#!/bin/sh
set -e

## Require:
#AFL_PATH

git clone https://github.com/google/AFL.git ${AFL_PATH} \
 && git -C ${AFL_PATH} checkout fab1ca5ed7e3552833a18fc2116d33a9241699bc \
 && cd ${AFL_PATH} \
 && make \
 && cd llvm_mode \
 && make
