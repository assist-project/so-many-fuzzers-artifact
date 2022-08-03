#!/bin/bash
set -e

## Install dependencies
apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        valgrind

clang_version=$(clang -dumpversion 2>/dev/null | cut -d'.' -f1-1)
if [[ -z "${clang_version}" || ${clang_version} -lt 8 ]];
then
  DEBIAN_FRONTEND=noninteractive apt-get install -y clang-8
fi

## Since target's preinstall is the last script using apt packages
## we conventionnaly remove the depos
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
rm -rf /var/lib/apt/lists/*
