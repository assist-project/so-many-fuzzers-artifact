#!/bin/bash
set -e

if [[ "$AFL_SANITIZED" = "effectivesan" ]]; then

	## Install EffectiveSan dependencies
	apt-get update \
	    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	        cmake \
		clang-4.0 \
		llvm-4.0-dev \
		wget \
		unzip

# Set default clang/llvm suite (from magma)
update-alternatives \
  --install /usr/lib/llvm              llvm             /usr/lib/llvm-4.0  20 \
  --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-4.0  \
  --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-4.0 \
  --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-4.0 \
  --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-4.0 \
  --slave   /usr/bin/llvm-c-test       llvm-c-test      /usr/bin/llvm-c-test-4.0 \
  --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-4.0 \
  --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-4.0 \
  --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-4.0 \
  --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-4.0 \
  --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-4.0 \
  --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-4.0 \
  --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-4.0 \
  --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-4.0 \
  --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-4.0 \
  --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-4.0 \
  --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-4.0 \
  --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-4.0 \
  --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-4.0 \
  --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-4.0 \
  --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-4.0 \
  --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-4.0

update-alternatives \
  --install /usr/bin/clang             clang            /usr/bin/clang-4.0  20 \
  --slave   /usr/bin/clang++           clang++          /usr/bin/clang++-4.0

fi

