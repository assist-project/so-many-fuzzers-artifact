#!/bin/bash

##Required
#SEED_FOLDER
#SYNC_FOLDER
#HONGGFUZZ_CMD
#LOG_PATH

unset QUIET SETCPU
## loops through options
while test $# -gt 0; do
  case "$1" in

    -q|--quiet)
      QUIET=1
      ;;

    --cpu)
      SETCPU=$2
      shift
      ;;

    *)
      echo "Error: invalid option." >&2
      exit 1
      ;;

   esac
   shift
done

## Magma:
# set default max log size to 1 MiB
LOGSIZE=${LOGSIZE:-$[1 << 20]}
echo "Start trial at: $(date -u '+%F %R')"

##set options and sanitizers flags
mkdir -p $SYNC_FOLDER/honggfuzz
mkdir -p $SYNC_FOLDER/honggfuzz/queue
mkdir -p $SYNC_FOLDER/honggfuzz/crashes
honggfuzz_options="--sanitizers_del_report=true -v --report $SYNC_FOLDER/honggfuzz/hfuzz.report --logfile $SYNC_FOLDER/honggfuzz/hfuzz.log --input $SEED_FOLDER --output $SYNC_FOLDER/honggfuzz/queue --crashdir $SYNC_FOLDER/honggfuzz/crashes -n 2 -- $HONGGFUZZ_CMD"

function run_fuzzer {
  cpu_id=$1
  if [ "$SETCPU" = "" ];
  then
    echo "run: ${HONGGFUZZ_PATH}/honggfuzz ${honggfuzz_options}"
    ${HONGGFUZZ_PATH}/honggfuzz ${honggfuzz_options}
  else
    echo "run: taskset -c ${cpu_id} ${HONGGFUZZ_PATH}/honggfuzz ${honggfuzz_options}"
    taskset -c ${cpu_id} ${HONGGFUZZ_PATH}/honggfuzz ${honggfuzz_options}
  fi
}

# go to our work directory
cd ${WORKDIR_PATH}

echo "  [+] seeds:              ${SEED_FOLDER}"
echo "  [+] root:               ${SYNC_FOLDER}"
echo "  [+] target command:     ${HONGGFUZZ_CMD}"
echo "  [+] entry:              ${ENTRY_POINT}"
if [ "${COMMIT_TO_FUZZ}" != "" ];
then
  actual_commit=$(cd ${CONTIKI_PATH} && git log -1 --pretty=format:"%h")
  echo "  [+] COMMIT:             ${actual_commit}"
fi
if [ "${BUGSET}" != "" ];         then echo "  [+] BUGSET:             ${BUGSET}"; fi

if [ "${QUIET}" = "" ]; then
	run_fuzzer "${SETCPU}"
else
	echo "Run honggfuzz (outputs in ${LOG_PATH}/honggfuzz.log)"
	run_fuzzer "${SETCPU}" > ${LOG_PATH}/honggfuzz.log
fi
