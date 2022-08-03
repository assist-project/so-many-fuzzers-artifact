#!/bin/bash

echo "[+] validate SymCC, afl-master and afl-slave crashes"
cp ${SYNC_FOLDER}/afl-slave/plot_data ${SYNC_FOLDER}/symcc/ \
  && ./validate-folder.sh ${SYNC_FOLDER}/symcc/
./validate-folder.sh ${SYNC_FOLDER}/afl-master/
./validate-folder.sh ${SYNC_FOLDER}/afl-slave/
