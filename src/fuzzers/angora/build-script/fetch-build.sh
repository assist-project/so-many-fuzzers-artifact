#!/bin/sh
set -e

## Require:
#AFL_PATH
#ANGORA_PATH
#SOFTWARE_PATH

git clone https://github.com/google/AFL.git ${AFL_PATH} \
 && git -C ${AFL_PATH} checkout fab1ca5ed7e3552833a18fc2116d33a9241699bc \
 && cd ${AFL_PATH} \
 && make

#&& ./build/install_tools.sh (using local pip)
git clone https://github.com/AngoraFuzzer/Angora.git ${ANGORA_PATH} \
 && git -C ${ANGORA_PATH} checkout 3cedcac8e65595cd2cdd950b60f654c93cf8cc2e \
 && cd ${ANGORA_PATH} \
 && ./build/install_rust.sh \
 && PREFIX=${SOFTWARE_PATH} ./build/install_llvm.sh \
 && virtualenv ${SOFTWARE_PATH}/angora-venv \
 && ${SOFTWARE_PATH}/angora-venv/bin/pip install --upgrade pip==9.0.3 \
 && ${SOFTWARE_PATH}/angora-venv/bin/pip install wllvm \
 && mkdir ${HOME}/go \
 && go get github.com/SRI-CSL/gllvm/cmd/... \
 && ./build/build.sh
