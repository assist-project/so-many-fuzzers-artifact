#!/bin/bash

##Required
#SEED_FOLDER
#SYNC_FOLDER
#AFL_CMD
#SYMCC_CMD
#LOG_PATH
##Optional
#AFL_SANITIZED
#AFL_SKIP_CPUFREQ
#AFL_NO_AFFINITY

unset QUIET SETCPU
## loops through options
while test $# -gt 0; do
  case "$1" in

    -q|--quiet)
      export AFL_NO_UI=1
      QUIET=1
      ;;

    --cpu)
      SETCPU=$2
      shift
      ;;

    *)
      exit 1
      ;;

   esac
   shift
done

## Magma:
# set default max log size to 1 MiB
LOGSIZE=${LOGSIZE:-$[1 << 20]}
echo "Start trial at $(date -u '+%F %R')"

##set AFL master/slave common options and sanitizers flags
afl_options="-i $SEED_FOLDER -o $SYNC_FOLDER -- $AFL_CMD"
case "${AFL_SANITIZED}" in
  asan)
    export ASAN_OPTIONS="abort_on_error=1:symbolize=0"
    afl_options="-m none -t +100 $afl_options"
    echo "  [+] Container configured for address sanitized target"
    ;;

  ubsan)
    export UBSAN_OPTIONS="halt_on_error=1:abort_on_error=1"
    echo "  [+] Container configured for undefined behaviors sanitized target"
    ;;

  effectivesan)
    export EFFECTIVE_ABORT=1
    export EFFECTIVE_MAXERRS=1
    afl_options="-m none -t +100 $afl_options"
    echo "  [+] Container configured for effectiveSan target"
    ;;

  *)
    ;;
esac

##set command according to SETCPU (AFL_NO_AFFINITY is assumed set to 1)
function run_afl_fuzzer {
  afl_type=$1
  cpu_id=$2
  if [ "$SETCPU" = "" ];
  then
    echo "run: ${AFL_PATH}/afl-fuzz ${afl_type} ${afl_options}"
    ${AFL_PATH}/afl-fuzz ${afl_type} ${afl_options}
  else
    echo "run: taskset -c ${cpu_id} ${AFL_PATH}/afl-fuzz ${afl_type} ${afl_options}"
    taskset -c ${cpu_id} ${AFL_PATH}/afl-fuzz ${afl_type} ${afl_options}
  fi
}

# go to our work directory
cd ${WORKDIR_PATH}

echo "  [+] seeds:                  ${SEED_FOLDER}"
echo "  [+] AFL root:               ${SYNC_FOLDER}"
echo "  [+] AFL target command:     ${AFL_CMD}"
echo "  [+] SymCC target command:   ${SYMCC_CMD}"
echo "  [+] entry:                  ${ENTRY_POINT}"
if [ "${COMMIT_TO_FUZZ}" != "" ];
then
  actual_commit=$(cd ${CONTIKI_PATH} && git log -1 --pretty=format:"%h")
  echo "  [+] COMMIT:             ${actual_commit}"
fi
if [ "${BUGSET}" != "" ];         then echo "  [+] BUGSET:             ${BUGSET}"; fi

echo
echo "Run afl-master (outputs in ${LOG_PATH}/afl-master.log)"
run_afl_fuzzer "-M afl-master" "${SETCPU}" > ${LOG_PATH}/afl-master.log &
if [ "${SETCPU}" != "" ]; then SETCPU=$((${SETCPU}+1)); fi

sleep 3

echo "Run afl-slave (outputs in ${LOG_PATH}/afl-slave.log)"
run_afl_fuzzer "-S afl-slave" "${SETCPU}" > ${LOG_PATH}/afl-slave.log &
if [ "${SETCPU}" != "" ]; then SETCPU=$((${SETCPU}+1)); fi

sleep 3

if [ "${QUIET}" = "" ]; then
    ~/.cargo/bin/symcc_fuzzing_helper -o ${SYNC_FOLDER} -a afl-slave -n symcc -- ${SYMCC_CMD}
else
    echo "Run SymCC (outputs in ${LOG_PATH}/symcc.log)"
    ~/.cargo/bin/symcc_fuzzing_helper -o ${SYNC_FOLDER} -a afl-slave -n symcc -- ${SYMCC_CMD} > ${LOG_PATH}/symcc.log 2>&1
fi
