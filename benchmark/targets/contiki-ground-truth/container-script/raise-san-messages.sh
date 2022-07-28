#!/bin/bash

## Check and count the number of input raising a runtime error message
## This is done by simply.
## - matching the output of a run with "runtime error" (usual output of an ubsan error)
## - matching the output of a run with "ERROR: AddressSanitizer" (usual output of an asan error)
regex_runtime_error='runtime error'
regex_addrsan_error='ERROR: AddressSanitizer'

IN_DIR=$1
CONTIKI_BIN=$2
raised_error=0
it=1
MAX=$(ls ${IN_DIR}/ | wc -l)
### configuration
TIMEOUT=5s

for file in ${IN_DIR}/*
do
  printf "\\r    Processing file ${it}/${MAX}... "
  output=$(timeout ${TIMEOUT} ${CONTIKI_BIN} ${file} 2>&1)
  if [[ ${output} =~ ${regex_addrsan_error} ]]
  then
      ## we match "raised an ASAN/UBSAN error" into ground truth crash triage
      echo "${file} raised an ASAN/UBSAN error! (AddressSanitizer error)"
      echo "${output}" > "${file}-output.txt"
      raised_error=$((raised_error+1))
  else
    if [[ ${output} =~ ${regex_runtime_error} ]]
    then
      ## we match "raised an ASAN/UBSAN error" into ground truth crash triage
      echo "${file} raised an ASAN/UBSAN error!"
      echo "${output}" > "${file}-output.txt"
      raised_error=$((raised_error+1))
    fi
  fi
  it=$((it+1))
done
echo

echo "[+] ${raised_error} files raising at leat one ASAN/UBSAN error!"
