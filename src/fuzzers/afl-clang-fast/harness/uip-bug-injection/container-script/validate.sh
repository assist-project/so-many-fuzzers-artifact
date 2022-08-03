#!/bin/bash

echo "[+] validate afl-master and afl-slave crashes"
./validate-folder.sh ${SYNC_FOLDER}/afl-master/
./validate-folder.sh ${SYNC_FOLDER}/afl-slave/
