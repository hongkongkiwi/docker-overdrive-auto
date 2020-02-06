#!/bin/bash

[ -z "$MP3_OUTPUT_DIR" ] && { echo >&2 "MP3_OUTPUT_DIR not set"; exit 1; }
[ ! -d "$MP3_OUTPUT_DIR" ] && { echo >&2 "MP3_OUTPUT_DIR does not exist"; exit 1; }
[ -z "$ODM_INPUT_DIR" ] && { echo >&2 "ODM_INPUT_DIR not set"; exit 1; }
[ ! -d "$ODM_INPUT_DIR" ] && { echo >&2 "ODM_INPUT_DIR does not exist"; exit 1; }
[ -z "$ODM_OUTPUT_DIR" ] && { echo >&2 "ODM_OUTPUT_DIR not set"; exit 1; }
[ ! -d "$ODM_OUTPUT_DIR" ] && { echo >&2 "ODM_OUTPUT_DIR does not exist"; exit 1; }

FILE_COUNT=`ls "${ODM_INPUT_DIR}"/*.odm 2>/dev/null | wc -l`

[ $FILE_COUNT -eq 0 ] && { echo >&2 "No files to process in ${ODM_INPUT_DIR}"; exit 1; }

echo "Processing $FILE_COUNT ODM files in ${ODM_INPUT_DIR}"
cd "${MP3_OUTPUT_DIR}"
shopt -s nullglob
for ODM_FILE in ${ODM_INPUT_DIR}/*.odm; do
  [ -s "$ODM_FILE" ] || { echo >&2 "# Skipping blank ODM file $ODM_FILE"; continue; } 
  OVERDRIVE_INFO=`overdrive info "$ODM_FILE" | tail -n-1 | tr "\t" "|" || { echo >&2 "Failed to get info from odm file"; continue; }`
  AUTHOR=`echo "$OVERDRIVE_INFO" | cut -d "|" -f1 | tr -d "," | awk '{$1=$1};1' || { echo >&2 "Failed to get info from odm file"; continue; }`
  BOOK_NAME=`echo "$OVERDRIVE_INFO" | cut -d "|" -f2 | awk '{$1=$1};1' || { echo >&2 "Failed to get info from odm file"; continue; }`
  [ -f "${ODM_FILE}.metadata" ] && rm "${ODM_FILE}.metadata"
  echo "# Found file `basename $ODM_FILE`" && \
  mv "$ODM_FILE" "${ODM_INPUT_DIR}/${AUTHOR}_${BOOK_NAME}.odm"
  ODM_FILE="${ODM_INPUT_DIR}/${AUTHOR}_${BOOK_NAME}.odm"
  FILENAME=$(basename -- "$ODM_FILE")
  LICENSE_FILE="${ODM_INPUT_DIR}/${FILENAME%.*}.license"
  METADATA_FILE="${ODM_INPUT_DIR}/${FILENAME%.*}.odm.metadata"

  echo " - Discovered book $BOOK_NAME by $AUTHOR" && \
  echo " - Downloading MP3s" && \
  overdrive download "$ODM_FILE" && \
  echo " - Returning Book"
  overdrive return "$ODM_FILE" && \
  echo " - Moving ODM file" && \
  mv "$ODM_FILE" "${ODM_OUTPUT_DIR}" && \
  [ -f "$LICENSE_FILE" ] && { echo " - Moving License File"; mv "$LICENSE_FILE" "${ODM_OUTPUT_DIR}"; }
  [ -f "$METADATA_FILE" ] && { echo " - Moving Metadata File"; mv "$METADATA_FILE" "${ODM_OUTPUT_DIR}"; }
done
