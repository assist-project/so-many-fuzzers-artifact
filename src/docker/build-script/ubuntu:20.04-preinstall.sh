#!/bin/bash
set -e

# Install common dependencies for contiki-ng on Ubuntu 20_04
apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-utils \
        build-essential \
        cmake \
	daemontools \
        git \
        python2 \
        python3-pip \
        rename \
	sudo \
        vim

pip3 install lit setuptools
cpan install Array::Utils

# EffectiveSan
. ${CONTAINER_SCRIPT}/effectivesan-preinstall-${OS_VERSION}.sh

