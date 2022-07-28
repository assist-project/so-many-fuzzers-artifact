#!/bin/bash

## The script creates .env files from .cfg files (to export containers's bash variables)
## It also sets user options, in particular:
## - the entry point protocol
## - the github commit to fuzz at
## - the Contiki-NG's configuration and project files, and
## - the afl "sanitized" option

if [ -e $2 ];
then
  rm $2
fi

while read line; do

  ## a bit hacky, but useful to set user options into the variables
  ## though it is specific to the harness
  case "$line" in
    AFL_COMPANION*)
        if [ ! -z "${SANITIZER}" ];
        then
		## EffectiveSan works on llvm-4 and only provides clang wrapper."
		## We use then the AFL-clang (instead of AFL-gcc) to instrument the target."
		if [ "${SANITIZER}" = "effectivesan" ];
		then
			line=$(echo "${line}" | sed s/gcc/clang/)
			line="${line}-effectivesan"
		else
          		line="${line}-${SANITIZER}"
		fi
        fi
	;;

    AFL_SANITIZED*)
        if [ -z "${SANITIZER}" ];
        then
          line="AFL_SANITIZED="
        else
          line="AFL_SANITIZED=${SANITIZER}"
        fi
         ;;

    BUGSET*)
        line="BUGSET=${BUGSET}"
        ;;

    CONTIKI_CONFIG_FILE*)
        line="CONTIKI_CONFIG_FILE=${CONTIKI_CONFIG_FILE}"
        ;;

    CONTIKI_MODULES_FILE*)
        line="CONTIKI_MODULES_FILE=${CONTIKI_MODULES_FILE}"
        ;;

    COMMIT_TO_FUZZ*)
        line="COMMIT_TO_FUZZ=${COMMIT_TO_FUZZ}"
        ;;

    ENTRY_POINT*)
        line="ENTRY_POINT=${ENTRY_POINT}"
         ;;

    FIXNAME*)
        line="FIXNAME=${FIXNAME}"
         ;;

    MAKE_ARGS*)
        line="MAKE_ARGS=${MAKE_ARGS}"
        ;;

    SYNC_FOLDER*)
        if [ ! -z "${TMPFS}" ];
        then
          line="SYNC_FOLDER=${TMPFS_PATH}"
        fi
        ;;

    WITNESS_ORACLE*)
	    if [ -z "${WITNESS_ORACLE}" ];
	    then
		    line="WITNESS_ORACLE="
	    else
		    line="WITNESS_ORACLE=${WITNESS_ORACLE}"
	    fi
	    ;;
   esac
  echo "export $line" >> $2

done <$1
