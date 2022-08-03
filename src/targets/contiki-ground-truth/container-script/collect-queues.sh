#!/bin/bash

## Usage: collect_queues.sh <destination_folder>
## - The script requires the environment variable: SYNC_FOLDER (to point to afl's output folder)
## - For each fuzzer into SYNC_FOLDER, the script collects the corpus and copy it into <destination_folder> with a suffix ":<nameFuzzer>"
##

unset QUEUE_DIR TIMESTAMPS_FILE
## loops through options
while getopts "+o:t:" opt; do

case "$opt" in

    "o")
         QUEUE_DIR="$OPTARG"
         ;;

     "t")
	 TIMESTAMPS_FILE="$OPTARG"
	 ;;

    "?")
         exit 1
         ;;

   esac
done

shift $((OPTIND-1))

if [ "$QUEUE_DIR" = "" -o ! -d "${SYNC_FOLDER}" ]; then

  cat 1>&2 <<_EOF_
Usage: $0 [ options ]

Required parameters:

  -o dir        - output directory to store the whole corpus

Required environment variable:

  SYNC_FOLDER   - input directory containing fuzzer output folders (afl -o option)

_EOF_
  exit 1
fi

if [ -e "$QUEUE_DIR" ] ;
then
  echo "Error $QUEUE_DIR exists"
  exit 1
fi


mkdir -p $QUEUE_DIR #queue
regex="^([0-9]+),"

for fuzzerfolder in $(ls ${SYNC_FOLDER})
do

  input_folder=${SYNC_FOLDER}/$fuzzerfolder
  output_folder=$QUEUE_DIR/$fuzzerfolder

## print the starting time for every fuzzer (with a fuzzer_stats file) ---> use PLOT_DATA
  if [ "$TIMESTAMPS_FILE" != "" -a -f "$input_folder/plot_data" ];
  then
    start_time=0
    while read line
    do
      if [[ $line =~ $regex ]];
      then
        start_time=${BASH_REMATCH[1]}
        echo "$fuzzerfolder starting time:$start_time" >> $TIMESTAMPS_FILE
        break
      fi
    done < "$input_folder/plot_data"
    if [[ $start_time -eq 0 ]];
    then
      echo "[-] error while reading $input_folder/plot_data"
      exit 1
    fi
  fi



  if [ ! -e "$input_folder/queue" ]; then continue; fi

  if [ "$(ls -A $input_folder/queue)" ];
  then
	  
    echo "- Collecting $(ls $input_folder/queue | wc -l) inputs from $fuzzerfolder -"

    if [ "$TIMESTAMPS_FILE" != "" ];
    then
      echo "  [+]queue filename,timestamp,seconds from start:" >> $TIMESTAMPS_FILE
      for file in $(ls $input_folder/queue/*)
      do
        input_timestamp=$(stat -c'%Y' $file)
        exposure_time=$((input_timestamp - start_time))
        if (( exposure_time < 0)); then exposure_time=0; fi
        echo "$(basename $file),$input_timestamp,$exposure_time" >> $TIMESTAMPS_FILE
      done
      echo "" >> $TIMESTAMPS_FILE
    fi

    mkdir -p $output_folder
    echo $input_folder/queue/* | xargs cp -t $output_folder
    echo $output_folder/* | xargs rename "s/$/:$fuzzerfolder/"
    echo $output_folder/* | xargs mv -t $QUEUE_DIR
    rm -fr $output_folder
  else
    echo "    $fuzzerfolder/queue empty."
  fi
done
