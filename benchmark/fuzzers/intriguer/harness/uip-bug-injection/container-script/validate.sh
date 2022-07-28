#!/bin/bash

echo "[+] validate intriguer, afl-master and afl-slave crashes"
./validate-folder.sh ${SYNC_FOLDER}/intriguer/
./validate-folder.sh ${SYNC_FOLDER}/afl-master/
./validate-folder.sh ${SYNC_FOLDER}/afl-slave/
