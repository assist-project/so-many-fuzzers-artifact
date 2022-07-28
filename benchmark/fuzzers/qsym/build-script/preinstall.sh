#!/bin/bash
set -e

apt-get update \
    && apt -y dist-upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	gcc-multilib \
	g++ \
	g++-multilib \
        libc6 \
        libstdc++6 \
        linux-libc-dev \
        llvm-dev \
        lsb-release \
        python-virtualenv
