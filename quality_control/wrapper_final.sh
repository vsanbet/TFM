#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=qc_international
#SBATCH --output=qc.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=05:00:00
#SBATCH --mem-per-cpu=2GB

# ============================================================================
# run_qc_pipeline.sh: Master wrapper to launch FastQC (as array) and MultiQC
# ============================================================================

set -euo pipefail

# ---------------------- Load Modules ----------------------

SCRIPT_DIR="/cluster/projects/nn8029k/PloidYeast/ValeriaS/scripts_aad/qc/"
source "${SCRIPT_DIR}/CESGA_module.sh"

# ---------------------- Default values ----------------------
SAMPLES_TSV="/cluster/projects/nn8029k/PloidYeast/ValeriaS/scripts_aad/qc/samples_fastq.tsv"
FASTQC_SCRIPT="$SCRIPT_DIR/fastqc.sh"
MULTIQC_SCRIPT="$SCRIPT_DIR/multiqc.sh"
FASTQC_DIR="fastqc_raw"
MULTIQC_DIR="multiqc"
LOG_DIR="logs_pre"
ACCOUNT="nn8029k"
FULL_RESULTS_PATH="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/added_internationals/pre_qc"

# ---------------------- Parse arguments ----------------------

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --samples) 
      SAMPLES_TSV="$2"
      shift 2
      ;;
    --fastqc-dir) 
      FASTQC_DIR="$2"
      shift 2
      ;;
    --multiqc-dir) 
      MULTIQC_DIR="$2"
      shift 2
      ;;
    --full-results-path)
      FULL_RESULTS_PATH="$2"
      shift 2
      ;;
    *) 
      echo "Unknown parameter passed: $1"
      echo "Usage: $0 [--samples <file>] [--fastqc-dir <dir>] [--multiqc-dir <dir>] [--full-results-path <path>]"
      exit 1
      ;;
  esac
done

# ---------------------- Prepare output directories ----------------------

mkdir -p "$FULL_RESULTS_PATH"
mkdir -p "$FULL_RESULTS_PATH/$FASTQC_DIR" "$FULL_RESULTS_PATH/$MULTIQC_DIR" "$FULL_RESULTS_PATH/$LOG_DIR"

# ---------------------- Calculate array range ----------------------
NUM_SAMPLES=$(wc -l < "$SAMPLES_TSV")
ARRAY_RANGE="0-$(($NUM_SAMPLES - 1))"

# ---------------------- Launch FastQC as array job ----------------------
echo "Launching FastQC for $NUM_SAMPLES samples..."
FASTQC_JOBID=$(sbatch --parsable --account=$ACCOUNT --array=$ARRAY_RANGE "$FASTQC_SCRIPT" \
  --samples "$SAMPLES_TSV" \
  --fastqc-dir "$FULL_RESULTS_PATH/$FASTQC_DIR" \
  --log-dir "$FULL_RESULTS_PATH/$LOG_DIR")

echo "Waiting for FastQC to finish (job ID: $FASTQC_JOBID)..."

# ---------------------- Launch MultiQC with dependency ----------------------
echo "Launching MultiQC after FastQC..."
MULTIQC_JOBID=$(sbatch --parsable --account=$ACCOUNT --dependency=afterok:$FASTQC_JOBID "$MULTIQC_SCRIPT" \
  --fastqc-dir "$FULL_RESULTS_PATH/$FASTQC_DIR" \
  --outdir "$FULL_RESULTS_PATH/$MULTIQC_DIR" \
  --log-dir "$FULL_RESULTS_PATH/$LOG_DIR")

echo "Submitted MultiQC (job ID: $MULTIQC_JOBID)"
