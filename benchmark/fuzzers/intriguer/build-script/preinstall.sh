#!/bin/bash
set -e

apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gcc-multilib \
        g++ \
        g++-multilib \
	libc6 \
        libstdc++6 \
        linux-libc-dev \
        llvm-dev \
        llvm-5.0 \
        python-virtualenv
