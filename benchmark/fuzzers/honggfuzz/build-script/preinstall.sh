#!/bin/bash
set -e

apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libbfd-dev \
    	libunwind-dev \
     	libblocksruntime-dev \
    	liblzma-dev
