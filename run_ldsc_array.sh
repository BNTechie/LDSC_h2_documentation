#!/bin/bash
set -eo pipefail

INPUT_DIR="/path/to/input_files"
OUTPUT_DIR="/path/to/output_directory"

FILE_EXT="*.ma"   # <-- change if needed (e.g. *.gz, *.txt)

mkdir -p "$OUTPUT_DIR"
mkdir -p logs

FILE_LIST="${OUTPUT_DIR}/file_list.txt"
FAILED_LIST="${OUTPUT_DIR}/failed_files.txt"
DONE_LIST="${OUTPUT_DIR}/completed_files.txt"

# create file list
find "$INPUT_DIR" -maxdepth 1 -type f -name "$FILE_EXT" | sort > "$FILE_LIST"

n=$(wc -l < "$FILE_LIST")

echo "Total files: $n"
echo "File list: $FILE_LIST"

# reset tracking files
: > "$FAILED_LIST"
: > "$DONE_LIST"

if [ "$n" -eq 0 ]; then
  echo "No input files found."
  exit 1
fi

# submit array job (max 20 parallel)
sbatch --array=1-"$n"%20 ldsc_h2_array.sh
