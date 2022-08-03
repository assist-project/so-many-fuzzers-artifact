#!/bin/bash

printf "\n-Fuzzing Trial Stopper: Manage fuzzing experiment termination-\n\n"

function usage {
  cat 1>&2 <<_EOF_
Usage: $0 (--all|-t container-id) [ --no-validation ]

  --help                      - show this usage

Required parameters:

  --all                       - stop all running containers
  --trial(-t)   container-id  - the trial container-id to stop

Optional parameters:

  --no-validation             - do not validate the fuzzing experiments

_EOF_
}

function error_usage {
  echo "Error: $1" >&2
  usage
  exit 1
}

unset NO_VALIDATION
unset CONTAINER_ID DO_ALL

## loops through options
while test $# -gt 0; do
  case "$1" in
    --all)
        DO_ALL="1"
        ;;

    --trial|-t)
        CONTAINER_ID="$2"
        shift
        ;;

    --help)
        usage
        exit 0
      ;;

    --no-validation)
        NO_VALIDATION="1"
        ;;

    *)
        error_usage "[-] invalid option"
        exit 1
         ;;
   esac
   shift
done

if [ -z "${DO_ALL}" -a -z "${CONTAINER_ID}" ];      then error_usage "Option --all or --trial required."; fi
if [ ! -z "${DO_ALL}" -a ! -z "${CONTAINER_ID}" ];  then echo "WARNING --all and --trial specified, --all ignored."; unset DO_ALL; fi

###
function go_to_validate {
  container=$1
  timeout_pid=$(docker top ${container} -C timeout -o pid | tail -n +2)
  kill ${timeout_pid}
  echo "[+] Stop signal sent to ${container}."
}
###

if [ ! -z "${NO_VALIDATION}" ]
then
  echo "WARNING do not validate experiments."
  if [ ! -z "${DO_ALL}" ]
  then
    docker stop $(docker ps -q)
  else
    docker stop ${CONTAINER_ID}
  fi
else
  if [ ! -z "${DO_ALL}" ]
  then
    for cid in $(docker ps -q)
    do
      go_to_validate ${cid}
    done
  else
    go_to_validate ${CONTAINER_ID}
  fi
fi

printf "[+] ... Trial(s) Terminated ... [+]\n\n"
