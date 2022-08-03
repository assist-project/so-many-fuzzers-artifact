#!/bin/bash

## - Gather seed pool, bad inputs or corpuses (both of them), from a fuzzing campaign folder 
## - Try also to catch the timetamps
##

INPUT_FOLDER=$1
TOOL_FOLDER=$2
OUTPUT_FOLDER=$3
COLLECTOR_TYPE=corpuses

mkdir -p ${OUTPUT_FOLDER}

## benchmark folder structure: runN -> tools -> sync_folder
##                                           -> log -> start_time

for trial_path in ${INPUT_FOLDER}/run*; do
	nb_run=$(basename $trial_path)
	sync_path=$(ls -d ${trial_path}/${TOOL_FOLDER}/sync[-_]folder)
        echo "sync at: ${sync_path}"

	# create output folder 'inputs' for trial input files

	if [ ! "${COLLECTOR_TYPE}" = crashes ];
	then
	        mkdir ${OUTPUT_FOLDER}/crashes_${nb_run}

		stamps_option=""
		if [ "${NO_TIMESTAMPS}" = "" ];
		then
			stamps_option="-t ${OUTPUT_FOLDER}/crashes_${nb_run}/timestamps-badinputs-${nb_run}"
		fi
		SYNC_FOLDER="${sync_path}" ./collect-queues.sh -o "${OUTPUT_FOLDER}/crashes_${nb_run}/inputs" ${stamps_option}
	fi 

	if [ ! "${COLLECTOR_TYPE}" = queues ];
	then
                mkdir ${OUTPUT_FOLDER}/queues_${nb_run}

                stamps_option=""
		if [ "${NO_TIMESTAMPS}" = "" ];
		then
			stamps_option="-t ${OUTPUT_FOLDER}/queues_${nb_run}/timestamps-queues-${nb_run}"
		fi
		SYNC_FOLDER="${sync_path}" LOG_PATH="${trial_path}/${TOOL_FOLDER}/log" ./collect-crashes.sh -h -o "${OUTPUT_FOLDER}/queues_${nb_run}/inputs" ${stamps_option}
	fi

	if [ "${COLLECTOR_TYPE}" = corpuses ];
	then 
		mv  ${OUTPUT_FOLDER}/crashes_${nb_run}/inputs/*  ${OUTPUT_FOLDER}/queues_${nb_run}/inputs/
		rm -r ${OUTPUT_FOLDER}/crashes_${nb_run}/inputs
		mv ${OUTPUT_FOLDER}/queues_${nb_run}/ ${OUTPUT_FOLDER}/corpuses_${nb_run}/

                if [ "${NO_TIMESTAMPS}" = "" ];
		then
			cat ${OUTPUT_FOLDER}/crashes_${nb_run}/timestamps-badinputs-${nb_run} >  ${OUTPUT_FOLDER}/corpuses_${nb_run}/corpus-timestamps-${nb_run}
			cat ${OUTPUT_FOLDER}/corpuses_${nb_run}/timestamps-queues-${nb_run}   >> ${OUTPUT_FOLDER}/corpuses_${nb_run}/corpus-timestamps-${nb_run}
                        rm -f ${OUTPUT_FOLDER}/corpuses_${nb_run}/timestamps-queues-${nb_run}
		fi
		rm -fr ${OUTPUT_FOLDER}/crashes_${nb_run}
	fi
done
