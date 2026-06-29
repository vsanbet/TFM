#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=03:00:00
#SBATCH --output=array_%A_%a.out
#SBATCH --error=array_%A_%a.err

set -euo pipefail

module purge
module load Qualimap/2.3-foss-2022b-R-4.2.2

IN_FILE="$1"
OUT_DIR="$2"
mkdir -p "$OUT_DIR"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$IN_FILE")
SAMPLE=$(echo "$LINE" | awk '{print $1}')
BAM=$(echo "$LINE" | awk '{print $2}')

SAMPLE_OUT="$OUT_DIR/$SAMPLE"
mkdir -p "$SAMPLE_OUT" || true


echo "Procesando: $SAMPLE  →  $BAM"

qualimap bamqc \
    -bam "$BAM" \
    -outdir "$SAMPLE_OUT" \
    --java-mem-size=16G
