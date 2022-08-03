#!/bin/bash

echo "[+] validate mopt-master and mopt-slave crashes"
./validate-folder.sh ${SYNC_FOLDER}/mopt-master/
./validate-folder.sh ${SYNC_FOLDER}/mopt-slave/
