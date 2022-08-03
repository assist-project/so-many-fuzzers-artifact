#!/bin/bash

## Require:
#SHARED
#LOG_PATH
#FIXNAME

mkdir -p ${SHARED}/crash-triage
## gather crashes and hangs found by all tools
./collect-crashes.sh -h -t ${SHARED}/crash-triage/timestamps -o bad-inputs > ${LOG_PATH}/triage.log
## apply Contiki-NG ground truth' crash triage (for the configured vulnerability's fixname)
perl ground-truth-triage.pl -validate -fix=${FIXNAME} -stamps=${SHARED}/crash-triage/timestamps -output=${SHARED}/crash-triage -- bad-inputs >> ${LOG_PATH}/triage.log 2>&1
