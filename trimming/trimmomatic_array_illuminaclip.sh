#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=trimmomatic
#SBATCH --output=trimmomatic_%A_%a.out
#SBATCH --time=8:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB

# -------------------------------
# SLURM array job to run Trimmomatic
# -------------------------------
# Each array task processes one line from the TSV (one sample).
#
# Usage (via wrapper):
#   ./run_trimmomatic.sh samples.tsv ./trimmed_headcrop15
# -------------------------------

set -euo pipefail

# --- Read input arguments ---
SAMPLES_TSV=$(readlink -f "$1")
OUTDIR=$(readlink -f "$2")

mkdir -p "$OUTDIR"

# Load Trimmomatic
module load Trimmomatic/0.39-Java-11

# -------------------------------
# Select the correct line from TSV
# -------------------------------
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES_TSV")
SAMPLE=$(echo "$LINE" | cut -f1)
READ1=$(echo "$LINE" | cut -f2)
READ2=$(echo "$LINE" | cut -f3)

echo "[$SLURM_ARRAY_TASK_ID] Processing sample: $SAMPLE"

# -------------------------------
# Run Trimmomatic (only keep paired)
# -------------------------------
TRIM_JAR="${EBROOTTRIMMOMATIC}/trimmomatic-0.39.jar"

java -Xmx28G -jar "$TRIM_JAR" PE -threads 8 -phred33 \
        "$READ1" "$READ2" \
        "$OUTDIR/${SAMPLE}_R1_paired.fastq.gz" /dev/null \
        "$OUTDIR/${SAMPLE}_R2_paired.fastq.gz" /dev/null \
        ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
	HEADCROP:15 \
	CROP:200 \
	TRAILING:25 \
	MINLEN:45
