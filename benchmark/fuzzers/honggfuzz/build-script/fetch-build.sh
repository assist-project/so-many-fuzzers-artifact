#!/bin/sh
set -e

## Require:
#HONGGFUZZ_PATH

git clone https://github.com/google/honggfuzz.git ${HONGGFUZZ_PATH} && \
    cd ${HONGGFUZZ_PATH} && \
    git checkout 0b4cd5b1c4cf26b7e022dc1deb931d9318c054cb && \
    CFLAGS="-O3 -funroll-loops" make

