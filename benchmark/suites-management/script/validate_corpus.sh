#!/bin/bash
#Require: export WORKPATH

printf "\n-Corpus Witness Verification-\n"
printf "  - fixname         :$1\n"
printf "  - inputfolder     :$2/$1-corpuses\n"
printf "  - outputfolder    :$3/$1\n"
printf "  - instrumentation :$4\n"

#Example:
#fixname=uip-overflow; \
#inputfolder=${WORKPATH}/campaign/$fixname; \
#outputfolder=${WORKPATH}/test/FC-with-Asan/${fixname}; \

if [ "$4" == "" ];
then
	option_san=""
else
	option_san="--san $4"
fi

fixname="$1"; \
inputfolder="$2/$fixname-corpuses"; \
outputfolder="$3/$fixname"; \
echo "input: $inputfolder"; \
mkdir -p ${outputfolder}; \
for tool in ${inputfolder}/*; do \
  base_tool=$(basename ${tool}) \
  && BUILD_ONLY=1 ${WORKPATH}/benchmark/suites-management/run-ground-truth-campaign.sh $option_san -b ${fixname} -f ${base_tool}; \
  for trial in ${tool}/corpuses_run*; do \
    nb=$(basename $trial) \
    && mkdir -p "${outputfolder}/${nb}/"  \
    && INPUT=${trial} IS_CORPUS=1 ${WORKPATH}/benchmark/suites-management/run-ground-truth-campaign.sh $option_san -b ${fixname} -f ${base_tool} --output ${outputfolder}/${nb}; \
    sleep 2; \
  done; \
  sleep 600;
done;
