#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=logs/multiqc_%j.out
#SBATCH --error=logs/multiqc_%j.err

set -euo pipefail

# ---------------------- Default values ----------------------
FASTQC_DIR="qc/fastqc_raw"
OUTDIR="qc"
LOG_DIR="logs"

# ---------------------- Parse arguments ----------------------
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --fastqc-dir) FASTQC_DIR="$2"; shift 2 ;;
    --outdir)     OUTDIR="$2"; shift 2 ;;
    --log-dir)    LOG_DIR="$2"; shift 2 ;;
    *) echo "❌ Unknown parameter: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$OUTDIR" "$LOG_DIR"

module load MultiQC/1.22.3-foss-2023b || true

echo "📊 Running MultiQC on: $FASTQC_DIR"
multiqc "$FASTQC_DIR" -o "$OUTDIR"
