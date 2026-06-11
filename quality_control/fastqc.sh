#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=05:00:00
#SBATCH --output=logs/fastqc_%A_%a.out
#SBATCH --error=logs/fastqc_%A_%a.err
# --array is passed externally by wrapper

set -euo pipefail

# ---------------------- Default values ----------------------
SAMPLES_TSV="samples.tsv"
FASTQC_DIR="qc/fastqc_raw"
LOG_DIR="logs"

# ---------------------- Parse arguments ----------------------
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --samples) SAMPLES_TSV="$2"; shift 2 ;;
    --fastqc-dir) FASTQC_DIR="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    *) echo "❌ Unknown parameter passed to fastqc.sh: $1"; exit 1 ;;
  esac
done

mkdir -p "$FASTQC_DIR" "$LOG_DIR"

# ---------------------- Extract sample ----------------------
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$SAMPLES_TSV")
READ1=$(echo "$LINE" | cut -f2)
READ2=$(echo "$LINE" | cut -f3)

echo "🔬 Running FastQC on: $READ1 and $READ2"

module load FastQC/0.12.1-Java-11

fastqc "$READ1" "$READ2" --outdir "$FASTQC_DIR"
