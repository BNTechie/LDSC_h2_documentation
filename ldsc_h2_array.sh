#!/bin/bash
#SBATCH --account=proto_psych_pgs
#SBATCH --job-name=ldsc_h2
#SBATCH --cpus-per-task=1
#SBATCH --time=1:00:00
#SBATCH --mem=15G
#SBATCH --partition=normal
#SBATCH --output=logs/ldsc_h2_%A_%a.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=<YOUR_EMAIL>

set -eo pipefail

source ~/.bashrc
conda activate ldsc

LDSC_DIR="/path/to/ldsc"
INPUT_DIR="/path/to/input_files"
OUTPUT_DIR="/path/to/output_directory"
LD_REF="/path/to/eur_w_ld_chr/"

FILE_LIST="${OUTPUT_DIR}/file_list.txt"
FAILED_LIST="${OUTPUT_DIR}/failed_files.txt"
DONE_LIST="${OUTPUT_DIR}/completed_files.txt"

mkdir -p "$OUTPUT_DIR"
mkdir -p logs

cd "$LDSC_DIR"

# pick file based on array index
input_file=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

if [ -z "$input_file" ]; then
  echo "No file for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
  exit 1
fi

# extract base name (works for .ma, .gz, .txt, etc.)
base=$(basename "$input_file")
base=${base%.*}

outprefix="${OUTPUT_DIR}/${base}"

echo "Task ID   : ${SLURM_ARRAY_TASK_ID}"
echo "Input     : $input_file"
echo "Base      : $base"
echo "Outprefix : $outprefix"

# skip if already done
if [ -f "${outprefix}_ldsc_h2.log" ]; then
  echo "Skipping already completed: $base"
  echo "$base" >> "$DONE_LIST"
  exit 0
fi

# -----------------------------
# Step 1: Munge sumstats
# -----------------------------
python munge_sumstats.py \
  --sumstats "$input_file" \
  --snp SNP \
  --a1 A1 \
  --a2 A2 \
  --frq freq \
  --signed-sumstats b,0 \
  --p p \
  --N-col N \
  --out "${outprefix}_munge"

# check munge output
if [ ! -f "${outprefix}_munge.sumstats.gz" ]; then
  echo "Missing munged output: $base"
  echo "$base" >> "$FAILED_LIST"
  exit 1
fi

# -----------------------------
# Step 2: Run LDSC h2
# -----------------------------
python ldsc.py \
  --h2 "${outprefix}_munge.sumstats.gz" \
  --ref-ld-chr "$LD_REF" \
  --w-ld-chr "$LD_REF" \
  --out "${outprefix}_ldsc_h2"

# -----------------------------
# Step 3: Mark done
# -----------------------------
echo "$base" >> "$DONE_LIST"
echo "Finished: $base"
