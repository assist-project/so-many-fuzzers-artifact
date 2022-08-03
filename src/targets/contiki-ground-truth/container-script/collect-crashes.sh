#!/bin/bash

## - The script requires the environment variable: SYNC_FOLDER (to point to afl's output folder)
## - Gather all crashes/hangs into <destination_folder>
##

function usage {
  cat 1>&2 <<_EOF_
  Usage: $0 -o dir [ options ]

Required parameters:

  -o dir        - output directory to store the crashes

Optional parameters:

  -t file       - save bad input timestamps into file
  -h            - also process hangs

Required environment variable:

  SYNC_FOLDER   - directory containing fuzzers' output folders (typically afl's root folder)

_EOF_
}

unset CRASH_DIR DO_HANGS TIMESTAMPS_FILE
## loops through options
while getopts "+o:ht:" opt; do
case "${opt}" in

    "o")
         CRASH_DIR="${OPTARG}"
         ;;

    "h")
        DO_HANGS="1"
        ;;

    "t")
        TIMESTAMPS_FILE="${OPTARG}"
        ;;

    "?")
         echo "Error: invalid option." >&2
         usage
         exit 1
         ;;

   esac
done

shift $((OPTIND-1))

if [ "${CRASH_DIR}" = "" -o ! -d "${SYNC_FOLDER}" ]; then usage; exit 0; fi
if [ -e "${CRASH_DIR}" ]; then echo "Error ${CRASH_DIR} exists" >&2; exit 1; fi

mkdir -p ${CRASH_DIR}
afl_plot_data_regex="^([0-9]+),"
contiki_bench_regex="Start trial at: ([0-9]+)"

## --- loop over fuzzer' folders
for fuzzerfolder in $(ls ${SYNC_FOLDER})
do
  if [ ! -d "${SYNC_FOLDER}/${fuzzerfolder}" ]; then continue; fi

  echo "- Collecting crashes from ${fuzzerfolder} -"
  ## every fuzzer has a temp. folder called output ... getting merged at the loop end
  input_folder=${SYNC_FOLDER}/${fuzzerfolder}
  output_folder=$CRASH_DIR/${fuzzerfolder}

  start_time=0
  ## if timestamps (-t)
  ## print the starting time for every fuzzer (extract from plot_data if it exists)
  ## - otherwie take the trial starting time
  if [ "${TIMESTAMPS_FILE}" != "" -a -f "${input_folder}/plot_data" ];
  then
    while read line
    do
      if [[ ${line} =~ ${afl_plot_data_regex} ]];
      then
        start_time=${BASH_REMATCH[1]}
        echo "${fuzzerfolder} starting time:${start_time}" >> ${TIMESTAMPS_FILE}
        break
      fi
    done < "${input_folder}/plot_data"
    if [[ ${start_time} -eq 0 ]]; then echo "Error while reading $input_folder/plot_data"; exit 1; fi
  else
    while read line
    do
      if [[ ${line} =~ ${contiki_bench_regex} ]];
      then
        start_time=${BASH_REMATCH[1]}
        echo "${fuzzerfolder} starting time:${start_time}" >> ${TIMESTAMPS_FILE}
        break
      fi
    done < "${LOG_PATH}/start_time"
  fi

  #get crashes
  if [ -d "${input_folder}/crashes" ];
  then
      if [ "$(ls -A ${input_folder}/crashes)" ];
      then
        mkdir -p ${output_folder}
        cp ${input_folder}/crashes/* ${output_folder}
        echo "    $(ls ${input_folder}/crashes/* | wc -l) crashes from ${fuzzerfolder}."

        if [ "${TIMESTAMPS_FILE}" != "" ];
        then
          echo "  [+]crashes filename,timestamp,seconds from start:" >> ${TIMESTAMPS_FILE}
          for file in $(ls ${input_folder}/crashes/*)
          do
            crash_timestamp=$(stat -c'%Y' ${file})
            echo "$(basename ${file}),${crash_timestamp},$((crash_timestamp - start_time))" >> ${TIMESTAMPS_FILE}
          done
          echo "" >> ${TIMESTAMPS_FILE}
        fi

      else
        echo "    ${fuzzerfolder}/crashes empty."
      fi
  fi

  #get hangs
  if [ "${DO_HANGS}" != "" ] && [ -d "${input_folder}/hangs" ] && [ "$(ls -A ${input_folder}/hangs)" ];
  then
      mkdir -p ${output_folder}
      cp ${input_folder}/hangs/* ${output_folder}
      rename "s/$/:hang/"  ${output_folder}/*
      echo "    $(ls ${input_folder}/hangs/* | wc -l) hangs from ${fuzzerfolder}."

      if [ "${TIMESTAMPS_FILE}" != "" ];
      then
        echo "  [+]hangs filename,timestamp,seconds from start:" >> ${TIMESTAMPS_FILE}
        for file in $(ls ${input_folder}/hangs/*)
        do
          hang_timestamp=$(stat -c'%Y' ${file})
          echo "$(basename ${file}),${hang_timestamp},$((hang_timestamp - start_time))" >> ${TIMESTAMPS_FILE}
        done
        echo "" >> ${TIMESTAMPS_FILE}
      fi

    else
      echo "    ${fuzzerfolder}/hangs empty."
    fi

  ## suffix all fuzzer's findings with its name and move files into the resulting folder (CRASH_DIR)
  if [ -d "${output_folder}" ];
  then
    rename "s/$/:${fuzzerfolder}/"  ${output_folder}/*  > /dev/null 2>&1
    mv ${output_folder}/*           ${CRASH_DIR}        > /dev/null 2>&1
    rm -fr ${output_folder}
  fi
done
