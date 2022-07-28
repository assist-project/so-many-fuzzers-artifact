#!/bin/bash
set -e

## Require:
#AFL_SANITIZED
#EFFECTIVESAN_PATH

if [ -t 1 ]
then
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BOLD="\033[1m"
    OFF="\033[0m"
else
    RED=
    GREEN=
    YELLOW=
    BOLD=
    OFF=
fi

if [[ "$AFL_SANITIZED" = "effectivesan" ]]; then

	### for Ubuntu-20 the build is a bit more difficult and:
	## 1. install gcc-4.8.2 toolchain (with some patches)
	## 2. install clang-4.0.1 using the toolchain, and
	## 3. install EffectiveSan

	## gcc-4.8.2
    echo -e "${GREEN}$0${OFF}: Downloading and checking gcc-4.8.2 toolchains"

	mkdir  ${SOFTWARE_PATH}/gcc-toolchain && cd ${SOFTWARE_PATH}/gcc-toolchain
	wget https://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2
	wget https://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2.sig
	wget https://ftp.gnu.org/gnu/gnu-keyring.gpg
	signature_invalid=`gpg --verify --no-default-keyring --keyring ./gnu-keyring.gpg gcc-4.8.2.tar.bz2.sig`
	if [ $signature_invalid ]; then echo "Invalid signature" ; exit 1 ; fi
	tar -xvjf gcc-4.8.2.tar.bz2
	cd gcc-4.8.2
	./contrib/download_prerequisites


	echo -e "${GREEN}$0${OFF}: Applying patches gcc-4.8.2 toolchains to be compiled using recent gcc"
	## patches (gcc)
    patch -i ${SOFTWARE_PATH}/effectivesan-patch/gcc-patch/cfns.gperf.patch gcc/cp/cfns.gperf
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/gcc-patch/cfns.h.patch     gcc/cp/cfns.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/gcc-patch/except.c.patch   gcc/cp/except.c
	## patches (libgcc)
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/aarch64-linux-unwind.h.patch libgcc/config/aarch64/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/alpha-linux-unwind.h.patch   libgcc/config/alpha/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/bfin-linux-unwind.h.patch    libgcc/config/bfin/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/i386-linux-unwind.h.patch    libgcc/config/i386/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/pa-linux-unwind.h.patch      libgcc/config/pa/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/sh-linux-unwind.h.patch      libgcc/config/sh/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/tilepro-linux-unwind.h.patch libgcc/config/tilepro/linux-unwind.h
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libgcc-patch/xtensa-linux-unwind.h.patch  libgcc/config/xtensa/linux-unwind.h
        ## patches (sanitizers)
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libsanitizer-patch/asan_linux.cc.patch          libsanitizer/asan/asan_linux.cc
	patch -i ${SOFTWARE_PATH}/effectivesan-patch/libsanitizer-patch/tsan_platform_linux.cc.patch libsanitizer/tsan/tsan_platform_linux.cc

	echo -e "${GREEN}$0${OFF}: Installing gcc-4.8.2 toolchains"
	## install gcc-4.8.2
	cd .. && mkdir gcc-4.8.2-build && cd gcc-4.8.2-build
	$PWD/../gcc-4.8.2/configure --prefix=$HOME/toolchains --enable-languages=c,c++
	make -j$(nproc)
	make install


	## llvm-4.0.1
	echo -e "${GREEN}$0${OFF}: clang-4.0.1 (to bootstrap EffectiveSan)"
	cd ${SOFTWARE_PATH}
	git clone -b llvmorg-4.0.1 https://github.com/llvm/llvm-project.git
	mkdir llvm-project/build && cd llvm-project/build
	CC=$HOME/toolchains/bin/gcc CXX=$HOME/toolchains/bin/g++ \
	  cmake -GNinja -DLLVM_ENABLE_PROJECTS="clang" \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_INSTALL_PREFIX=$PWD/../install \
	  -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,$HOME/toolchains/lib64 -L$HOME/toolchains/lib64" \
	  $PWD/../llvm
	ninja -j2 install

    ## to comply with EffectiveSan script
    cp $PWD/../install/bin/clang++      $PWD/../install/bin/clang++-4.0
    cp $PWD/../install/bin/llvm-config  $PWD/../install/bin/llvm-config-4.0
    export PATH="$PWD/../install/bin:$PATH"

	## EffectiveSan
	cd ${SOFTWARE_PATH}
	git clone https://github.com/GJDuck/EffectiveSan.git ${EFFECTIVESAN_PATH}
	git -C ${EFFECTIVESAN_PATH} checkout 12e711d39f6b0bddf0b0f97df2eeb7e29752c6b6

    cd ${EFFECTIVESAN_PATH}
	git apply ${SOFTWARE_PATH}/effectivesan-patch/EffectiveSan-Ubuntu20.patch
	./build.sh release

fi
