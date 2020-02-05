#!/bin/bash

cd "${OUTPUT_DIR}"
for ODM_FILE in "${MONITOR_DIR}/"*.odm
do
  overdrive download "$ODM_FILE" && \
  overdrive return "$ODM_FILE" && \
  rm "$ODM_FILE"
done
