#!/bin/bash

##
## Warning:
## set corresponding container's WORKDIR_PATH if modified (Dockerfile's USER_NAME or WORKDIR_PATH)
WORKDIR_PATH=/home/benchng/

printf "\n-Campaign Runner: build and run fuzzing experiments-\n\n"
## Run a fuzzing campaign (N similar trials <fuzzer,bug>)
# 1) build docker image
# 2) run trials
# 3) crash triage
#

function usage {
  cat 1>&2 <<_EOF_
Usage: $0 [ options ]

  --help                    - show this usage

Required parameters:

  --fuzzer(-f)  name        - fuzzing tool name
  --target(-s)  name        - SUT name to take as target
  --harness(-h) name        - harness to use for fuzzing

Optional parameters:

  --cores (-c)  list        - list of CPUs to confine fuzzers
  --dockerfile  path        - points to a specific dockerfile to build docker image
  -n            number      - number of trials to run concurrently
  --output      path        - output folder containing fuzzing logs, results and triages
  --tag                     - specify a tag for the docker image
  --timeout(-t) time        - timeout for the fuzzing trials
  --tmpfs       size        - mount fuzzers root folder using a temporary file system of <size> (you must also provide the container path to mount using TMPFS_PATH)

Optional Flags:
  BUILD_ONLY                - stop after building Docker image

_EOF_
}

function error_usage {
  echo "Error: $1" >&2
  usage
  exit 1
}

unset OUTPUT_FOLDER TAG
unset CORES NB_TRIALS TIMEOUT TMPFS
unset TRIAL_FUZZER TRIAL_TARGET TRIAL_HARNESS
unset DOCKER_PATH

ROOT_PATH=${ROOT_PATH:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"}
## default values
TIMEOUT="1d"
NB_TRIALS=1
OUTPUT_FOLDER=${ROOT_PATH}/campaign_result
## default values

## loops through options
while test $# -gt 0; do
  case "$1" in
    --asan)
        SANITIZE="$2"
        shift
        ;;

    --cores|-c)
        CORES="$2"
        shift
        ;;

    --dockerfile)
        DOCKER_PATH="$2"
        shift
        ;;

    --fuzzer|-f)
        TRIAL_FUZZER="$2"
        shift
        ;;

    --harness|-h)
        TRIAL_HARNESS="$2"
        shift
        ;;

    --help)
        usage
        exit 0
      ;;

    -n)
        NB_TRIALS="$2"
        shift
        ;;

    --output|-o)
        OUTPUT_FOLDER="$2"
        shift
        ;;

    --tag)
        TAG="$2"
        shift
        ;;

    --target|-s) #for sut
        TRIAL_TARGET="$2"
        shift
        ;;

    --timeout|-t)
        TIMEOUT="$2"
        shift
        ;;

    --tmpfs)
        TMPFS="$2"
        if [ -z "${TMPFS_PATH}" ]; then error_usage "TMPFS_PATH must have the container path to mount tmpfs at."; fi
        shift
        ;;

    *)
        error_usage "[-] invalid option"
        exit 1
         ;;
   esac
   shift
done

##[TODO]: check cores/nb_trials consistency

## CONFIGURE PATH
FUZZER_PATH=${ROOT_PATH}/fuzzers/${TRIAL_FUZZER}
TARGET_PATH=${ROOT_PATH}/targets/${TRIAL_TARGET}
HARNESS_PATH=${ROOT_PATH}/fuzzers/${TRIAL_FUZZER}/harness/${TRIAL_HARNESS}
## CONFIGURE PATH

if [ -z "${TRIAL_FUZZER}" -o -z "${TRIAL_TARGET}" -o -z "${TRIAL_HARNESS}" ]; then error_usage "Need a fuzzer+target+harness."; fi
if [ ! -e ${FUZZER_PATH} ]; then error_usage "Fuzzer ${TRIAL_FUZZER} unknown."; fi
if [ ! -e ${TARGET_PATH} ]; then error_usage "Target ${TRIAL_TARGET} unknown."; fi
if [ ! -e ${HARNESS_PATH} ]; then error_usage "Harness ${TRIAL_HARNESS} for ${TRIAL_FUZZER} unknown."; fi
if [ -z "${TAG}" ]; then TAG="${TRIAL_FUZZER}-${TRIAL_TARGET}"; fi

#### check for OS configuration
OS_VERSION=ubuntu:20.04
if [ -e "${FUZZER_PATH}/setting/os.env" ]; then source ${FUZZER_PATH}/setting/os.env; fi
####

## build
# check if the docker image tag is already available
is_built=$(docker image ls | grep "^${TAG}")
if [[ -z "${is_built}" ]];
then
  ## not built yet, lets do it
  printf "\n[+] -- Build docker image: ${TAG}:\n"
  if [ ! -z "${DOCKER_PATH}" ]; then
    dockerfile="${ROOT_PATH}/${DOCKER_PATH}"
  else
    dockerfile="${ROOT_PATH}/docker/Dockerfile"
  fi
  echo "  - use ${dockerfile}";
  echo "  - with OS ${OS_VERSION}"
  docker build \
    --build-arg OS_VERSION=${OS_VERSION} \
    --build-arg TRIAL_FUZZER=${TRIAL_FUZZER} --build-arg TRIAL_TARGET=${TRIAL_TARGET} --build-arg TRIAL_HARNESS=${TRIAL_HARNESS} \
    --build-arg USER_ID=$(id -u ${USER}) --build-arg GROUP_ID=$(id -g ${USER}) \
    --build-arg AFL_SANITIZED=${SANITIZER} \
    -t ${TAG} \
    -f ${dockerfile} ${ROOT_PATH}
  #
  if [ $? -eq 0 ];
  then
    printf "[+] Docker Image ${TAG} built.\n\n"
  else
    echo "[!] An error occured during the image compilation [!]" >&2
    exit 1
  fi
else
  printf "[+] Docker Image ${TAG} already exist.\n\n"
fi


if [ ! -z "${BUILD_ONLY}" ]
then
  printf "[+] Build Only enabled, stop here.\n\n"
  exit 0
fi

## docker run trials and validation
tmpfs_option=""
if [ ! -z "${TMPFS}" ]
then
  tmpfs_option="--mount type=tmpfs,tmpfs-size=${TMPFS},destination=${TMPFS_PATH} --env TMPFS_PATH=${TMPFS_PATH}"
fi

function run_trial {
  shared_folder=$1
  if [ -e "${shared_folder}" ];
  then
    echo "[!] Output folder ${shared_folder} already exists [!]" >&2
    exit 1
  fi
  mkdir "${shared_folder}"

  echo "[+] Start ${TAG} output folder:"                      >  ${shared_folder}/container.log &
  cid=$(docker run -dt --rm --security-opt seccomp:unconfined \
    -v  ${shared_folder}:${WORKDIR_PATH}/shared \
    ${tmpfs_option} \
    ${TAG} \
    bash -c "source ${WORKDIR_PATH}/.bashrc \
     && cd script \
     && ./fuzz-and-validate.sh ${TIMEOUT}")
  container_id=$(cut -c-12 <<< $cid$)
  echo "   - ${container_id} running... ------------------------------------" >> ${shared_folder}/container.log &
  docker logs -f "${container_id}"                                            >> ${shared_folder}/container.log &
  exit_code=$(docker wait $container_id)
  echo "   - ${container_id} terminated at $(date -u '+%F %R') ---------------"  >> ${shared_folder}/container.log &
  exit $exit_code
}

#### clean and create output folder
REAL_OUTPUT=$(realpath "${OUTPUT_FOLDER}")
if [ "${REAL_OUTPUT}" = "" ];
then
	echo "Error: the path to the output folder ${OUTPUT_FOLDER} should exist."
	exit 1
fi
	
mkdir -p ${REAL_OUTPUT}
####

echo "[+] Run ${NB_TRIALS} trial(s):"
echo "    - of ${TAG}"
echo "    - for ${TIMEOUT}"
echo "    - at $(date -u '+%F %R')"
echo "    - output folders: ${REAL_OUTPUT}"
echo

if [ ${NB_TRIALS} -eq 1 ];
then
  echo "[+] Launch ${TRIAL_FUZZER} (log in ${REAL_OUTPUT}/${TRIAL_FUZZER})"
  run_trial "${REAL_OUTPUT}/${TRIAL_FUZZER}" &
else
  i=0
  while [ $i -lt $NB_TRIALS ];
  do
    i=$((i+1))
    mkdir -p ${REAL_OUTPUT}/run${i}

    echo "[+] Launch ${TRIAL_FUZZER}_${i} (log in ${REAL_OUTPUT}/run${i}/${TRIAL_FUZZER})"
    run_trial "${REAL_OUTPUT}/run${i}/${TRIAL_FUZZER}" &
  done
fi

printf "[+] ... Fuzzing In Progress ... [+]\n\n"
