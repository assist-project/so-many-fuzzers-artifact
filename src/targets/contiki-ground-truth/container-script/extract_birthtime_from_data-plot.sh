#!/bin/bash

## From a data_plot and a queue id, return the relative exposure-time in seconds (the seconds spent from the start until when the file has been created)
## - For consistency, make sure the queue's inputfile id and the plot_data file are from the same AFL instance
## - The computation is based on AFL's plot_data timestamps which (usually) have a granularity of 5 seconds.

function usage {
  cat 1>&2 <<_EOF_
  Usage: $0 id plot_data

Required parameters:

  id            - the inputfile's id into AFL queue folder
  plot_data     - AFL's plot_data file

_EOF_
}

if [ "$#" -ne 2 ]; then echo "[-] Error, the script needs two parameters"; usage; exit 0; fi
unset ID_TO_FIND PLOT_DATA_FILE
ID_TO_FIND=$1
PLOT_DATA_FILE=$2

if [ ! -r "$PLOT_DATA_FILE" ];  then echo "[-] Error, $PLOT_DATA_FILE is not readable"; exit 0; fi

## Step1: extract the start time and the number of seeds from the first line of data in plot_data
## Regex: ---- data_plot example:
##  unix_time, cycles_done, cur_path, paths_total, pending_total, pending_favs, map_size, unique_crashes, unique_hangs, max_depth, execs_per_sec
## 1619790359,           0,        0,           3,             3,            2,    0.06%,              0,            0,         1,        324.32
## Catch unix_time and paths_total
plot_data_regex="^([0-9]+),\s+[0-9]+,\s+[0-9]+,\s+([0-9]+),"
start_time=0
seed_number=0

{
## we remove the header
read -r
while read line
do
  if [[ ${line} =~ ${plot_data_regex} ]];
  then

    if [ "$start_time" -eq 0 ]; then
      ## initialize
      start_time=${BASH_REMATCH[1]}
      seed_number=${BASH_REMATCH[2]}
      echo "Init: Starting time:${start_time}, Seeds: $seed_number"

    else
      current_time=${BASH_REMATCH[1]}
      current_id=$((BASH_REMATCH[2]-seed_number))
      echo "At time:${current_time}, number of created files into the seed pool: $current_id"

      if [ $current_id -ge "$ID_TO_FIND" ]; then
        ## the current number of file is greater than the input's id (the file has been created)
        birth_time=$((current_time-start_time))
        echo "Birth time of $ID_TO_FIND: $birth_time"
        exit 0
      fi
    fi
  else
    echo "[-] Error while matching data_plot content"
    echo "$line"
    exit 1
  fi
done
} < "$PLOT_DATA_FILE"
