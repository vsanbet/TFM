#!/bin/bash
#SBATCH -J trimmomatic                
#SBATCH -o trimmomatic_%j.out         
#SBATCH -e trimmomatic_%j.err         
#SBATCH -t 3:00:00                    
#SBATCH -N 1                          
#SBATCH -n 8                          
#SBATCH --mem=32G                     

# -------------------------------
# SLURM script to run Trimmomatic
# -------------------------------
# This script trims the first 15 bases from Illumina paired-end reads
# using the HEADCROP option of Trimmomatic.
#
# INPUT:
#   - A TSV file with three columns (tab-separated):
#       SAMPLE_ID   READ1   READ2
#   - The TSV should include a header row.
#
# OUTPUT:
#   - For each sample, four files are produced in OUTDIR:
#       SAMPLE_R1_paired.fastq.gz     (paired surviving reads from R1)
#       SAMPLE_R1_unpaired.fastq.gz   (R1 reads without a mate after trimming)
#       SAMPLE_R2_paired.fastq.gz     (paired surviving reads from R2)
#       SAMPLE_R2_unpaired.fastq.gz   (R2 reads without a mate after trimming)
#
# USAGE:
#   sbatch trimmomatic.slurm <samples.tsv> <outdir>
#
# Example:
#   sbatch trimmomatic.slurm samples_all.tsv ./trimmed_headcrop15
# -------------------------------

# --- Read input arguments ---
SAMPLES_TSV=$1   # Path to the input TSV file
OUTDIR=$2        # Directory where output files will be stored

# Check arguments
if [[ -z "$SAMPLES_TSV" || -z "$OUTDIR" ]]; then
  echo "Usage: sbatch trimmomatic.slurm <samples.tsv> <outdir>"
  exit 1
fi

# Create output directory if it does not exist
mkdir -p "$OUTDIR"

# Load Trimmomatic module on CESGA
module load Trimmomatic/0.39-Java-11

# -------------------------------
# Main loop: process each sample
# -------------------------------
# Read the TSV file line by line
# Skip the header
while IFS=$'\t' read -r SAMPLE READ1 READ2; do
  if [[ "$SAMPLE" != "SAMPLE_ID" ]]; then
    echo "Processing sample: $SAMPLE"

    # Run Trimmomatic in paired-end mode
    # - HEADCROP:15 removes the first 15 bases from each read
    # - 4 output files: paired and unpaired reads for R1 and R2
    trimmomatic PE -threads 8 \
      "$READ1" "$READ2" \
      "$OUTDIR/${SAMPLE}_R1_paired.fastq.gz" /dev/null \
      "$OUTDIR/${SAMPLE}_R2_paired.fastq.gz" /dev/null \
      HEADCROP:15
  fi
done < "$SAMPLES_TSV"
