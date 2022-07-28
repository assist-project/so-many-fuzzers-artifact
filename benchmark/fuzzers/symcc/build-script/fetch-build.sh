#!/bin/sh
set -e

## Require:
#AFL_PATH
#LLVM_PATH
#SYMCC_PATH

export CC=clang-10
export CXX=clang++-10

git clone -b v2.56b https://github.com/google/AFL.git ${AFL_PATH} \
 && cd ${AFL_PATH} \
 && make

# Download the LLVM sources already so that we don't need to get them again when
# SymCC changes
git clone -b llvmorg-10.0.1 --depth 1 https://github.com/llvm/llvm-project.git ${LLVM_PATH}


git clone https://github.com/eurecom-s3/symcc ${SYMCC_PATH} \
    && git -C ${SYMCC_PATH} checkout 4fddd3cfcdbd6813ee23da51af58a31d73794ea6 \
    && cd ${SYMCC_PATH} \
    && git submodule init && git submodule update

# Build a version of SymCC with the simple backend to compile libc++
mkdir ${SYMCC_PATH}/symcc_build_simple \
    && cd ${SYMCC_PATH}/symcc_build_simple \
    && cmake -G Ninja \
	-DCMAKE_C_COMPILER=${CC} \
        -DCMAKE_CXX_COMPILER=${CXX} \
        -DLLVM_DIR="$(llvm-config --cmakedir)" \
        -DQSYM_BACKEND=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
         ${SYMCC_PATH} \
    && ninja check

# Build SymCC with the Qsym backend
mkdir ${SYMCC_PATH}/symcc_build \
    && cd ${SYMCC_PATH}/symcc_build \
    &&  cmake -G Ninja \
        -DCMAKE_C_COMPILER=${CC} \
        -DCMAKE_CXX_COMPILER=${CXX} \
        -DLLVM_DIR="$(llvm-config --cmakedir)" \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
        ${SYMCC_PATH} \
    && ninja check \
    && cargo install --path ${SYMCC_PATH}/util/symcc_fuzzing_helper

# Build libc++ with SymCC using the simple backend
mkdir ${SYMCC_PATH}/libcxx_symcc \
    && cd ${SYMCC_PATH}/libcxx_symcc \
    && export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && mkdir libcxx_symcc_build \
    && cd libcxx_symcc_build \
    && cmake -G Ninja ${LLVM_PATH}/llvm \
         -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
         -DLLVM_TARGETS_TO_BUILD="X86" \
         -DLLVM_DISTRIBUTION_COMPONENTS="cxx;cxxabi;cxx-headers" \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX=${SYMCC_PATH}/libcxx_symcc_install \
         -DCMAKE_C_COMPILER=${SYMCC_PATH}/symcc_build_simple/symcc \
         -DCMAKE_CXX_COMPILER=${SYMCC_PATH}/symcc_build_simple/sym++ \
    && ninja distribution \
    && ninja install-distribution

