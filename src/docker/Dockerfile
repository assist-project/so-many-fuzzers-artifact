ARG  OS_VERSION=ubuntu:20.04
FROM $OS_VERSION

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=benchng
ARG OS_VERSION=ubuntu:20.04

## --- Create user and working directory (workdir) ---
ENV USER_NAME     ${USER_NAME}
ENV WORKDIR_PATH  /home/${USER_NAME}

RUN echo "Make home at ${WORKDIR_PATH}" \
    && mkdir -p /home && mkdir -p ${WORKDIR_PATH} \
    && groupadd -og ${GROUP_ID} benchng \
    && useradd -ol -u ${USER_ID} -K UMASK=0000 -d ${WORKDIR_PATH} -g ${USER_NAME} ${USER_NAME} \
    && chown ${USER_NAME}:${USER_NAME} ${WORKDIR_PATH} \
    && echo "${USER_NAME}:gnhcneb" | chpasswd && usermod -a -G sudo ${USER_NAME}
######

## --- Set benchmark paths from arguments ---
ARG TRIAL_FUZZER
ARG TRIAL_TARGET
ARG TRIAL_HARNESS
## Host Contiki-ng benchmark paths
ENV TRIAL_FUZZER  ${TRIAL_FUZZER}
ENV TRIAL_TARGET  ${TRIAL_TARGET}
ENV TRIAL_HARNESS ${TRIAL_HARNESS}
ARG CONTIKI_DOCKER=docker
ARG CONTIKI_FUZZER=fuzzers/${TRIAL_FUZZER}
ARG CONTIKI_TARGET=targets/${TRIAL_TARGET}
ARG CONTIKI_HARNESS=${CONTIKI_FUZZER}/harness/${TRIAL_HARNESS}
ARG AFL_SANITIZED=${SANITIZER}
######

## --- Set container (OS common packages) ---
ENV  CONTAINER_SCRIPT /root/install-image-script
RUN  mkdir ${CONTIKI_DOCKER}

COPY ${CONTIKI_DOCKER}/build-script/${OS_VERSION}-preinstall.sh ${CONTAINER_SCRIPT}/${OS_VERSION}-preinstall.sh
COPY ${CONTIKI_DOCKER}/build-script/effectivesan-preinstall-${OS_VERSION}.sh ${CONTAINER_SCRIPT}/effectivesan-preinstall-${OS_VERSION}.sh
RUN  echo "Preinstall: ${OS_VERSION}" && ${CONTAINER_SCRIPT}/${OS_VERSION}-preinstall.sh
######


## --- Preinstall fuzzer and target (root) ---
COPY  ${CONTIKI_FUZZER}/build-script     ${WORKDIR_PATH}/fuzzer
RUN   chown -R ${USER_NAME}:${USER_NAME} ${WORKDIR_PATH}/fuzzer \
	   && ${WORKDIR_PATH}/fuzzer/preinstall.sh

COPY  ${CONTIKI_TARGET}/build-script     ${WORKDIR_PATH}/target
RUN   chown -R ${USER_NAME}:${USER_NAME} ${WORKDIR_PATH}/target \
	   && ${WORKDIR_PATH}/target/preinstall.sh
######


## --- Create shared folder with guest/host access ---
ENV SHARED   ${WORKDIR_PATH}/shared
RUN mkdir -p ${SHARED} \
   && chown ${USER_NAME}:${USER_NAME} ${SHARED} \
   && chmod 744 ${SHARED}
######

## --- Create Harness folder ---
ENV SOFTWARE_PATH     ${WORKDIR_PATH}/software
ENV HARNESS_PATH      ${SOFTWARE_PATH}/${TRIAL_HARNESS}

RUN  mkdir            ${SOFTWARE_PATH}
RUN  mkdir            ${HARNESS_PATH}

COPY ${CONTIKI_TARGET}/common-harnesses  ${HARNESS_PATH}
COPY ${CONTIKI_HARNESS}                  ${HARNESS_PATH}

RUN  chown -R ${USER_NAME}:${USER_NAME}  ${SOFTWARE_PATH}
######

##
##
## --- Install software (user) ---
##
##

USER      ${USER_NAME}:${USER_NAME}
WORKDIR   ${WORKDIR_PATH}

## --- Install fuzzer and target (user) ---
COPY ${CONTIKI_FUZZER}/setting/fuzzer.env ${WORKDIR_PATH}/fuzzer
RUN /bin/bash -c "source ${WORKDIR_PATH}/fuzzer/fuzzer.env && ${WORKDIR_PATH}/fuzzer/fetch-build.sh"

COPY ${CONTIKI_TARGET}/setting/target.env ${WORKDIR_PATH}/target
RUN /bin/bash -c "source ${WORKDIR_PATH}/target/target.env && ${WORKDIR_PATH}/target/fetch-build.sh"
######

## -- Install EffectiveSan if needed
ENV  EFFECTIVESAN_PATH ${SOFTWARE_PATH}/effectivesan
COPY ${CONTIKI_DOCKER}/build-script/effectivesan-install-${OS_VERSION}.sh ${SOFTWARE_PATH}/effectivesan-install-${OS_VERSION}.sh
COPY ${CONTIKI_DOCKER}/build-script/effectivesan-patch                    ${SOFTWARE_PATH}/effectivesan-patch
RUN  ${SOFTWARE_PATH}/effectivesan-install-${OS_VERSION}.sh

## --- Instrument with harness scripts (fuzzer's entry point)---
RUN mkdir -p ${WORKDIR_PATH}/bin
RUN   /bin/bash -c "source ${WORKDIR_PATH}/fuzzer/fuzzer.env \
  &&  source ${WORKDIR_PATH}/target/target.env \
  &&  source ${HARNESS_PATH}/setting/instrument.env \
  &&  ${HARNESS_PATH}/build-script/instrument.sh"
######

## --- set path to log folder
ENV  LOG_PATH ${SHARED}/log

## --- auto sourcing when running a container manually
RUN echo "source ${WORKDIR_PATH}/fuzzer/fuzzer.env \
       && source ${WORKDIR_PATH}/target/target.env \
       && source ${HARNESS_PATH}/setting/instrument.env \
       && source ${HARNESS_PATH}/setting/run.env" >> $WORKDIR_PATH/.bashrc


## --- Import common helper scripts used for fuzzing/triage
## - trial run template (from fuzzer)
## - triage and validate (from target)
WORKDIR  ${WORKDIR_PATH}
RUN  mkdir -p                               script
COPY ${CONTIKI_FUZZER}/container-script/*   script/
COPY ${CONTIKI_TARGET}/container-script/*   script/
COPY ${CONTIKI_HARNESS}/container-script/*  script/
######
