#!/bin/bash
# Wrapper to launch Trimmomatic as an array job

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <samples.tsv> <outdir>"
  exit 1
fi

SAMPLES_TSV=$1 # TSV con sample_name, dircetorio read 1 y directorio read2
OUTDIR=$2

# Count number of lines in TSV (excluding header)
TOTAL_LINES=$(wc -l < "$SAMPLES_TSV")
LAST_LINE=$TOTAL_LINES

# Directory where this wrapper is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Check that trimmomatic_array.sh exists
if [[ ! -f "${SCRIPT_DIR}/trimmomatic_array.sh" ]]; then
  echo "Error: trimmomatic_array.sh not found in ${SCRIPT_DIR}"
  exit 1
fi

# Submit array job with correct resources
sbatch --account=nn8029k --time=8:00:00 --mem=32G --cpus-per-task=8 -N 1 \
  --array=2-${LAST_LINE} \
  "${SCRIPT_DIR}/trimmomatic_array_illuminaclip.sh" "$SAMPLES_TSV" "$OUTDIR"
