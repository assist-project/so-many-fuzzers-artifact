#!/bin/sh
set -e

## Require:
#CONTIKI_PATH
#COMMIT_TO_FUZZ

## install contiki-ng
git clone https://github.com/contiki-ng/contiki-ng.git ${CONTIKI_PATH}
## commit version to checkout
if [ -z "${COMMIT_TO_FUZZ}" ];
then
  git -C ${CONTIKI_PATH} pull
else
  git -C ${CONTIKI_PATH} checkout ${COMMIT_TO_FUZZ}
fi
