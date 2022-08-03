#!/bin/sh
set -e

## Require:
#AFL_PATH
#MOPT_PATH

git clone https://github.com/puppet-meteor/MOpt-AFL ${MOPT_PATH} \
  && git -C ${MOPT_PATH} checkout a9a5dc5c0c291c1cdb09b2b7b27d7cbf1db7ce7b \
  && cd ${AFL_PATH} \
  && make
