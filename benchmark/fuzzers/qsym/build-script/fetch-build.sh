#!/bin/sh
set -e

## Require:
#AFL_PATH
#PY_VENV
#QSYM_PATH
#SOFTWARE_PATH
#Z3_PATH

git clone https://github.com/google/AFL.git ${AFL_PATH} \
 && git -C ${AFL_PATH} checkout fab1ca5ed7e3552833a18fc2116d33a9241699bc \
 && cd ${AFL_PATH} \
 && make

## create a local venv for user
virtualenv ${PY_VENV}

#&& ./setup.sh (using local pip)
git clone https://github.com/sslab-gatech/qsym.git ${QSYM_PATH} \
 && git -C ${QSYM_PATH} checkout 4fa4363cd09d40a422efa24d359b87f849202d4a \
 && cd ${QSYM_PATH} \
 && git submodule init \
 && git submodule update \
 && cd third_party/z3 \
 && rm -rf build \
 && ./configure --prefix=${Z3_PATH} --pypkgdir=${PY_VENV}/lib/python-2.7/site-packages \
 && cd build \
 && make -j$(nproc) \
 && make install \
 && mv python ${Z3_PATH} \
 && cd .. \
 && rm -rf build \
 && ./configure --x86 --prefix=${Z3_PATH} --pypkgdir=${PY_VENV}/lib/python-2.7/site-packages \
 && cd build  \
 && make -j$(nproc) \
 && mkdir ${Z3_PATH}/lib32 \
 && cp libz3.so ${Z3_PATH}/lib32

## FIX itertools version
cd ${QSYM_PATH} \
  && ${PY_VENV}/bin/pip install setuptools==44.0.0 --upgrade \
  && ${PY_VENV}/bin/pip install more-itertools==5.0.0 \
  && ${PY_VENV}/bin/pip install .

# build test directories
cd ${QSYM_PATH}/tests \
  && ${PY_VENV}/bin/python build.py

#run ${PY_VENV}/bin/python -m pytest -n $(nproc) to check qsym installation (require to run a container accepting ptrace uses)
