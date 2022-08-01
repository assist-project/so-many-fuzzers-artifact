#!/bin/bash
#Require: export WORKPATH

printf "\n-Corpus Gathering-\n"
printf "  - fixname         :$1\n"
printf "  - inputfolder     :$2\n"
printf "  - outputfolder    :$3\n"

#Example:
#fixname=uip-overflow; \
#inputfolder=${WORKPATH}/campaign/; \
#outputfolder=${WORKPATH}/test/corpus; \


fixname=$1; \
inputfolder=$2; \
outputfolder=$3; \
pushd ${WORKPATH}/benchmark/targets/contiki-ground-truth/container-script; \
for tool in ${inputfolder}/${fixname}/run1/*; do \
 base_tool=$(basename ${tool}); \
 mkdir -p $WORKPATH/${outputfolder}/${fixname}; \
 ./collect-corpuses.sh ${inputfolder}/${fixname} ${base_tool} ${outputfolder}/${fixname}/${base_tool}; \
done; \
popd
