#!/bin/bash

##Required
#SEED_FOLDER
#SYNC_FOLDER
#AFL_CMD
#MOPT_L
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
mopt_options="-L $MOPT_L -i $SEED_FOLDER -o $SYNC_FOLDER -- $AFL_CMD"
case "${AFL_SANITIZED}" in
  asan)
    export ASAN_OPTIONS="abort_on_error=1:symbolize=0"
    afl_options="-m none -t +100 ${afl_options}"
    mopt_options="-m none -t +100 ${mopt_options}"
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
    mopt_options="-m none -t +100 ${mopt_options}"
    echo "  [+] Container configured for effectiveSan target"
    ;;

  *)
    ;;
esac

##set command according to SETCPU (AFL_NO_AFFINITY is assumed set to 1)
##AFL_PATH set to Mopt-AFL path (fuzzer.conf)
function run_mopt_afl_fuzzer {
  afl_type=$1
  cpu_id=$2
  options=$3
  if [ "$SETCPU" = "" ];
  then
    echo "run: ${AFL_PATH}/afl-fuzz ${afl_type} ${options}"
    ${AFL_PATH}/afl-fuzz ${afl_type} ${options}
  else
    echo "run: taskset -c ${cpu_id} ${AFL_PATH}/afl-fuzz ${afl_type} ${options}"
    taskset -c ${cpu_id} ${AFL_PATH}/afl-fuzz ${afl_type} ${options}
  fi
}

# go to our work directory
cd ${WORKDIR_PATH}

echo "  [+] seeds:                    ${SEED_FOLDER}"
echo "  [+] AFL root:                 ${SYNC_FOLDER}"
echo "  [+] mopt-AFL target command:  ${AFL_CMD}"
echo "  [+] MOpt L option is:         ${MOPT_L}"
echo "  [+] entry:                    ${ENTRY_POINT}"
if [ "${COMMIT_TO_FUZZ}" != "" ];
then
  actual_commit=$(cd ${CONTIKI_PATH} && git log -1 --pretty=format:"%h")
  echo "  [+] COMMIT:             ${actual_commit}"
fi
if [ "${BUGSET}" != "" ];         then echo "  [+] BUGSET:             ${BUGSET}"; fi

echo
echo "Run MOpt-AFL master (outputs in ${LOG_PATH}/mopt-afl-master.log)"
run_mopt_afl_fuzzer "-M mopt-master" "${SETCPU}" "${afl_options}" > ${LOG_PATH}/mopt-afl-master.log &
if [ "${SETCPU}" != "" ]; then SETCPU=$((${SETCPU}+1)); fi

sleep 3

if [ "$QUIET" = "" ]; then
  run_mopt_afl_fuzzer "-S mopt-slave" "${SETCPU}" "${mopt_options}"
else
  echo "Run MOpt-AFL slave (outputs in ${LOG_PATH}/mopt-afl-slave.log)"
  run_mopt_afl_fuzzer "-S mopt-slave" "${SETCPU}" "${mopt_options}" > ${LOG_PATH}/mopt-afl-slave.log 2>&1
fi
