#!/bin/bash
set -e

apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        golang-go   \
        python-dev  \
        python-pip  \
        virtualenv  \
	      wget        \
	      zlib1g-dev
