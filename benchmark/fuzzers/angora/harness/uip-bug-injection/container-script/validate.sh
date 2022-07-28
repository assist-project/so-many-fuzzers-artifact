#!/bin/bash

echo "[+] validate angora, afl-master and afl-slave crashes"
cp ${SYNC_FOLDER}/afl-slave/plot_data ${SYNC_FOLDER}/angora/ \
 && ./validate-folder.sh ${SYNC_FOLDER}/angora/
./validate-folder.sh ${SYNC_FOLDER}/afl-master/
./validate-folder.sh ${SYNC_FOLDER}/afl-slave/
