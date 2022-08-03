#!/bin/bash
set -e

## Install dependencies
apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cmake \
	wget \
	unzip \
	gcc-multilib

