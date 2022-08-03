#!/bin/bash

printf "\n-Contiki-NG Ground Truth Campaign Configuration-\n\n"
## Run a ground truth campaign on contiki-ng (N similar trials <fuzzer,fixname>)
# 1) set host shared volume and environment variables
# 2) generate env file
# 3) build and run docker image
#

## Define exceptions: Fuzzer having their own Dockerfile
## Map: {fuzzer-name -> Dockerfile_path}
## Note: the docker build running the dockerfile is always run at the root folder
##
fuzzer_exceptions=( ["savior"]="fuzzers/savior/Dockerfile" )

function usage {
  cat 1>&2 <<_EOF_
Usage: $0 (-a|-b) fix_name -f tool_name [ options ]

  --help                       - print this help page

Required parameters:

  -a            fix_name       - build Contiki-NG after fix_name
  -b            fix_name       - build Contiki-NG before fix_name
  --fuzzer (-f) tool_name      - fuzzing tool name

Optional parameters:

  --cores (-c)   list          - list of CPUs to confine fuzzers [not available yet]
  -n             number        - number of trials to run concurrently
  --oracle       companion     - force the binary used to detect witnesses (during validation phase)
  --output       path          - folder to put fuzzing logs, results and crash triage outputs
  --san          sanitizer     - add a sanitizer (asan or ubsan) during the greybox fuzzer instrumentation
  --tag          docker_name   - specify a tag for the docker image
  --timeout (-t) time          - set timeout for the fuzzing trials
  --tmpfs        size          - mount fuzzers root folder using a temporary file system of <size>

Ground Truth optional parameters:
  --config       config        - contiki-ng configuration (uip, uip-rpl-classic, sicslowpan, coap or snmp) to inject input packets [by default set acc. to the paper]

_EOF_
}

function error_usage {
  echo "Error: $1" >&2
  usage
  exit 1
}

function is_valid_sanitizer {
  case "$1" in
    asan)
    ;;
    effectivesan)
    ;;
    ubsan)
    ;;
    *)
    error_usage "Error: Unknown sanitizer."
  esac
}

function is_valid_config {
  case "$1" in
    uip)
    ;;
    uip-rpl-classic)
    ;;
    sicslowpan)
    ;;
    snmp)
    ;;
    coap)
    ;;
    *)
    error_usage "Unknown configuration: $1."
  esac
}

function is_valid_entry_point {
  case "$1" in
    uip)
    ;;
    sicslowpan)
    ;;
    snmp)
    ;;
    coap)
    ;;
    *)
    error_usage "Unknown entry point: $1."
  esac
}

function is_valid_oracle {
 case "$1" in
    clang-effectivesan)
	    ;;
    *)
	    error_usage "Unknown oracle: $1."
 esac
}

##Set default variables acc. to a fuzzer
function set_environment_for_fuzzer {
	case "$1" in
		honggfuzz)
			if [ -z "${WITNESS_ORACLE}" ]; then WITNESS_ORACLE="hfuzz-clang"; fi
			;;
		*)
	esac
}

unset CONTIKI_CONFIG ENTRY_POINT
unset OUTPUT_FOLDER TAG
unset TIMEOUT NB_TRIALS CORES SANITIZER TMPFS
unset FIXNAME DO_BEFORE DO_AFTER
unset WITNESS_ORACLE

## main folder
ROOT_PATH=${ROOT_PATH:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"}
## default values
TIMEOUT="1d"
NB_TRIALS=1
## default values

## loops through options
while test $# -gt 0; do
  case "$1" in
    --san)
        SANITIZER="$2"
        ## check values
        is_valid_sanitizer ${SANITIZER}
        shift
        ;;

    --cores|-c)
        CORES="$2"
        shift
        ;;

    --fuzzer|-f)
        FUZZER="$2"
        FUZZER_PATH=${ROOT_PATH}/fuzzers/${FUZZER}
        if [ ! -e ${FUZZER_PATH} ]; then error_usage "Fuzzer ${FUZZER} unknown. (see in ${ROOT_PATH}/fuzzers/ for available fuzzers)"; fi
        set_environment_for_fuzzer ${FUZZER}
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

    --oracle)
        WITNESS_ORACLE="$2"
	is_valid_oracle ${WITNESS_ORACLE}
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

    --timeout|-t)
        TIMEOUT="$2"
        shift
        ;;

    --tmpfs)
        TMPFS="$2"
        shift
        ;;

##Ground Truth options
    --after|-a)
        FIXNAME="$2"
        DO_AFTER="1"
        shift
        ;;

    --before|-b)
        FIXNAME="$2"
        DO_BEFORE="1"
        shift
        ;;

    --config)
        CONTIKI_CONFIG="$2"
        is_valid_config ${CONTIKI_CONFIG}
        shift
        ;;

    *)
        error_usage "[-] invalid option"
        exit 1
         ;;
   esac
   shift
done

if [ -z "${FIXNAME}" ]; then error_usage "Choose a vulnerability's fixname (option -a or -b)."; fi
if [ -z "${DO_AFTER}" -a -z "${DO_BEFORE}" ]; then error_usage "Options a and b are exclusive."; fi
if [ -z "${FUZZER}" ]; then error_usage "Choose a fuzzer to evaluate (option -f)."; fi
## prevent from building SAVIOR with EffectiveSan
#if [[ "${FUZZER}" = "savior" ]] && [[ "${SANITIZER}" = "effectivesan" ]];
#then
#	error_usage "SAVIOR cannot run with EffectiveSanitizer."
#fi
## implicit with ground truth fuzzing (paper's configuration)
TARGET=contiki-ground-truth
HARNESS=contiki-ng-fuzzing

printf "[+] Get corresponding commit...("
if [ ! -z "${DO_BEFORE}" ]; then printf "before"; fi
if [ ! -z "${DO_AFTER}" ];  then printf "after";  fi
printf " ${FIXNAME})\n"
SECURITY_FIXES_PATH=${ROOT_PATH}/targets/${TARGET}/common-harnesses/info/security-fixes.txt
##### Get corresponding commit
##        fix name         PR ID       after      before
regex="([a-zA-Z0-9_\-]+) +([0-9]+) +([a-f0-9]+) +([a-f0-9]+)"
while read -r fn; do
if [[ $fn =~ $regex ]];
then
  if [[ ${BASH_REMATCH[1]} == ${FIXNAME} ]]
  then
    ## security-fixes lists first the last commit fixing the vulnerability and then the one before
    if [ "$DO_AFTER" != "" ]; then
        COMMIT_TO_FUZZ=${BASH_REMATCH[3]}
    else
        COMMIT_TO_FUZZ=${BASH_REMATCH[4]}
    fi
  fi
fi
done < <(cat ${SECURITY_FIXES_PATH})
## check
if [ "${COMMIT_TO_FUZZ}" = "" ]; then error_usage "Error: $FIXNAME not found. (See ${SECURITY_FIXES_PATH} for possible fixnames)"; fi
#####
echo "  - ... commit found: ${COMMIT_TO_FUZZ}."

##### adjust contiki-ng configuration acc. to the fixname (if no --config option)
function set_fixname_protocol {
  if [ -z "${CONTIKI_CONFIG}" ];
  then
    case "$1" in
      coap*)
	      CONTIKI_CONFIG="coap"
	      ;;
      uip-rpl-classic*)
	      CONTIKI_CONFIG="uip-rpl-classic"
	      ;;
      uip*)
        CONTIKI_CONFIG="uip"
        ;;
      6lowpan*|srh*|nd6*)
	      CONTIKI_CONFIG="sicslowpan"
        ;;
      snmp*)
        CONTIKI_CONFIG="snmp"
	      ;;
     esac
  fi
}
set_fixname_protocol ${FIXNAME}


echo "[+] Configure for: ${CONTIKI_CONFIG}..."
if [ "${SANITIZER}" != "" ]; then echo "    - with ${SANITIZER}."; fi
##### Set Contiki-NG's configuration and modules files corresponding to the required CONTIKI_CONFIG
case ${CONTIKI_CONFIG} in
"snmp")
  ENTRY_POINT="snmp"
  CONTIKI_MODULES_FILE=Makefile.snmp-modules
  ;;
"coap")
  ENTRY_POINT="coap"
  CONTIKI_MODULES_FILE=Makefile.coap-modules
  ;;
"uip-rpl-classic")
  ENTRY_POINT="uip"
  MAKE_ARGS="MAKE_ROUTING=MAKE_ROUTING_RPL_CLASSIC"
  CONTIKI_CONFIG_FILE=no-checksum-conf.h
  CONTIKI_MODULES_FILE=Makefile.bug-validation-modules
  ;;
"uip")
  ENTRY_POINT="uip"
  CONTIKI_MODULES_FILE=Makefile.bug-validation-modules
  ;;
"sicslowpan")
  ENTRY_POINT="sicslowpan"
  CONTIKI_MODULES_FILE=Makefile.bug-validation-modules
  ;;
esac
#####
##### Safety check
if [ "${ENTRY_POINT}" = "" ];
then
	error_usage "Entry point missing."
fi


##### Auto TAG if not set
if [ -z "$TAG" ]; then
  TAG="fuzz-${FUZZER}-${FIXNAME}-${ENTRY_POINT}"
  if [ ! -z "${SANITIZER}" ]; then
   TAG="${TAG}-${SANITIZER}";
 fi
fi
#####

FUZZER_PATH=${ROOT_PATH}/fuzzers/${FUZZER}
TARGET_PATH=${ROOT_PATH}/targets/${TARGET}
HARNESS_PATH=${ROOT_PATH}/fuzzers/${FUZZER}/harness/${HARNESS}

unset TMPFS_PATH
if [ ! -z "$TMPFS" ]; then TMPFS_PATH="/home/benchng/tmpfs"; fi

echo "[+] Write .env files..."
export COMMIT_TO_FUZZ CONTIKI_CONFIG_FILE CONTIKI_MODULES_FILE ENTRY_POINT FIXNAME MAKE_ARGS SANITIZER TMPFS TMPFS_PATH WITNESS_ORACLE
script_folder=${ROOT_PATH}/suites-management/script/
#### created files for environment variables for building/running docker images
${script_folder}/configure.sh ${FUZZER_PATH}/setting/fuzzer.conf      ${FUZZER_PATH}/setting/fuzzer.env
${script_folder}/configure.sh ${TARGET_PATH}/setting/target.conf      ${TARGET_PATH}/setting/target.env
${script_folder}/configure.sh ${HARNESS_PATH}/setting/instrument.conf ${HARNESS_PATH}/setting/instrument.env
${script_folder}/configure.sh ${HARNESS_PATH}/setting/run.conf        ${HARNESS_PATH}/setting/run.env


OPTIONS="--tag $TAG"
if [ ! -z "${CORES}" ];          then OPTIONS="${OPTIONS} -c ${CORES}"; fi
if [ ! -z "${NB_TRIALS}" ];      then OPTIONS="${OPTIONS} -n ${NB_TRIALS}"; fi
if [ ! -z "${OUTPUT_FOLDER}" ];  then OPTIONS="${OPTIONS} -o ${OUTPUT_FOLDER}"; fi
if [ ! -z "${TIMEOUT}" ];        then OPTIONS="${OPTIONS} -t ${TIMEOUT}"; fi
if [ ! -z "${TMPFS}" ];          then OPTIONS="${OPTIONS} --tmpfs ${TMPFS}"; echo "TMPFS_PATH=${TMPFS_PATH}"; fi
#
if [[ "${FUZZER}" = "savior" ]]; then OPTIONS="${OPTIONS} --dockerfile ${fuzzer_exceptions[${FUZZER}]}"; fi
###

#### Ok, we are good to go!
if [ ! -z "${INPUT}" ];
then
	echo "[+] Run: ${ROOT_PATH}/docker/run-fuzzing-campaign-new.sh with:"
	echo "    -f ${FUZZER}"
	echo "    -s ${TARGET}"
	echo "    -h contiki-ng-fuzzing"
	echo "    -i ${INPUT}"
	echo "    and options: ${OPTIONS}"
	${ROOT_PATH}/docker/run-fuzzing-campaign-new.sh -f "${FUZZER}" -s "${TARGET}" -h "contiki-ng-fuzzing" --input_sync "${INPUT}" ${OPTIONS}
else
	echo "[+] Run: ${ROOT_PATH}/docker/run-fuzzing-campaign.sh with:"
	echo "    -f ${FUZZER}"
	echo "    -s ${TARGET}"
	echo "    -h contiki-ng-fuzzing"
	echo "    and options: ${OPTIONS}"
	${ROOT_PATH}/docker/run-fuzzing-campaign.sh -f "${FUZZER}" -s "${TARGET}" -h "contiki-ng-fuzzing" \
	  ${OPTIONS}
fi
####

### Clean generated .env files
rm ${FUZZER_PATH}/setting/fuzzer.env ${TARGET_PATH}/setting/target.env ${HARNESS_PATH}/setting/instrument.env ${HARNESS_PATH}/setting/run.env 2>/dev/null
####
