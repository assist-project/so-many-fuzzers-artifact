#!/bin/bash
set -e

# Install common dependencies for contiki-ng on Ubuntu 16.04
apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-utils \
        build-essential \
        cmake \
        daemontools \
        git \
        python \
        python-pip \
	python3 \
	sudo \
        vim

cpan install Array::Utils

# EffectiveSan
. ${CONTAINER_SCRIPT}/effectivesan-preinstall-${OS_VERSION}.sh
