#!/bin/bash

## Require:
#SHARED
#LOG_PATH
#FIXNAME

case "${AFL_SANITIZED}" in
	gcc*|clang*)
		;;
	afl*)
		;;
	asan)
		export ASAN_OPTIONS="log_path=asan.log:abort_on_error=1:symbolize=1"
		;;
	ubsan)
		export UBSAN_OPTIONS="log_path=ubsan.log:halt_on_error=1:abort_on_error=1"
		;;
	ubsan-trunc)
		export UBSAN_OPTIONS="log_path=ubsant.log:halt_on_error=1:abort_on_error=1"
		;;
        effectivesan)
		export EFFECTIVE_LOGFILE=effectivesan.log
                export EFFECTIVE_ABORT=1
                export EFFECTIVE_MAXERRS=1
		;;
	*)
		;;
esac



mkdir -p ${LOG_PATH}
mkdir -p ${SHARED}/crash-triage

## handle sync-folders (a root folder from fuzzing trial) and corpuses
if [ ! "${IS_CORPUS}" = "" ]
then
	echo "Validate corpus at ${WORKDIR_PATH}/input/inputs"
	input_folder="${WORKDIR_PATH}/input/inputs"
	`cp ${WORKDIR_PATH}/input/*timestamps* ${SHARED}/crash-triage/timestamps`;
else
        ## gather crashes and hangs found by all tools
	echo "Validate reported inputs at ${PWD}/bad-inputs"
        SYNC_FOLDER=${WORKDIR_PATH}/input/sync_folder ./collect-crashes.sh -h -t ${SHARED}/crash-triage/timestamps -o bad-inputs > ${LOG_PATH}/triage.log
	input_folder="bad-inputs"
fi

## apply Contiki-NG ground truth' crash triage (for the configured vulnerability's fixname)
perl ground-truth-triage-new.pl -validate -fix=${FIXNAME} -stamps=${SHARED}/crash-triage/timestamps -output=${SHARED}/crash-triage -- ${input_folder} >> ${LOG_PATH}/triage.log 2>&1
