#!/bin/sh
set -e

## Require:
#AFL_PATH
#INTRIGUER_PATH
#WORKDIR_PATH
#Z3_PATH

git clone https://github.com/google/AFL.git ${AFL_PATH} \
 && git -C ${AFL_PATH} checkout fab1ca5ed7e3552833a18fc2116d33a9241699bc \
 && cd ${AFL_PATH} \
 && make

## create a local venv for user
virtualenv ${PY_VENV}

git clone https://github.com/seclab-yonsei/intriguer.git ${INTRIGUER_PATH} \
  && git -C ${INTRIGUER_PATH} checkout 4d41176f77bc09a46a6157b83e421f2a2b4ba1ef \
  && cd ${INTRIGUER_PATH} \
  && git submodule init \
  && git submodule update \
  && cd third_party/z3 \
  && rm -rf build \
  && ${PY_VENV}/bin/python scripts/mk_make.py --prefix=${Z3_PATH} --python --pypkgdir=${Z3_PATH}/lib/python-2.7/site-packages \
  && cd build \
  && make -j$(nproc) \
  && make install \
  && cd ${INTRIGUER_PATH}/pintool \
  && make -j$(nproc) \
  && cd ${INTRIGUER_PATH}/traceAnalyzer \
  && make -j$(nproc) \
  && patch ${INTRIGUER_PATH}/intriguer_afl/afl-fuzz.c < ${WORKDIR_PATH}/fuzzer/patch/afl-fuzz.patch \
  && cd ${INTRIGUER_PATH}/intriguer_afl \
  && make -j$(nproc)

## the patch fixes intriguer disk usage issue (remove tmpdir in every iteration)
