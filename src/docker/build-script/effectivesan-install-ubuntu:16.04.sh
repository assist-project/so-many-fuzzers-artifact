#!/bin/bash
set -e

## Require:
#AFL_SANITIZED
#EFFECTIVESAN_PATH

if [[ "$AFL_SANITIZED" = "effectivesan" ]]; then
  git clone https://github.com/GJDuck/EffectiveSan.git ${EFFECTIVESAN_PATH} \
  && git -C ${EFFECTIVESAN_PATH} checkout 12e711d39f6b0bddf0b0f97df2eeb7e29752c6b6
  cd ${EFFECTIVESAN_PATH} && rm -fr build/ && ./build.sh release
fi

