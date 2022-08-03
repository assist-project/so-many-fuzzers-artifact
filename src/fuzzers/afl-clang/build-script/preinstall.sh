#!/bin/bash
set -e

apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang

# Set default clang/llvm suite (from magma)
update-alternatives \
  --install /usr/lib/llvm              llvm             /usr/lib/llvm-3.8  20 \
  --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-3.8  \
  --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-3.8 \
  --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-3.8 \
  --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-3.8 \
  --slave   /usr/bin/llvm-c-test       llvm-c-test      /usr/bin/llvm-c-test-3.8 \
  --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-3.8 \
  --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-3.8 \
  --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-3.8 \
  --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-3.8 \
  --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-3.8 \
  --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-3.8 \
  --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-3.8 \
  --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-3.8 \
  --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-3.8 \
  --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-3.8 \
  --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-3.8 \
  --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-3.8 \
  --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-3.8 \
  --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-3.8 \
  --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-3.8 \
  --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-3.8

update-alternatives \
  --install /usr/bin/clang             clang            /usr/bin/clang-3.8  20 \
  --slave   /usr/bin/clang++           clang++          /usr/bin/clang++-3.8
