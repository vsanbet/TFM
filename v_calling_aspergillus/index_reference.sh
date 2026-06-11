#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=index_ref
#SBATCH --output=index_ref_%j.log
#SBATCH --error=index_ref_%j.err
#SBATCH --time=00:15:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "❌ Usage: sbatch index_reference.slurm.sh <REFERENCE.fasta|.fa|.fna>"
  exit 1
fi

REFERENCE="$1"
DICT="${REFERENCE%.*}.dict"
FAI="${REFERENCE}.fai"

# Load required modules CESGA
# module purge
# module load cesga/2020
# module load picard/2.25.5
# module load gatk/4.2.6.1
# module load samtools/1.19


# Load required modules SAGA
module purge
module load picard/3.0.0-Java-17
module load GATK/4.5.0.0-GCCcore-12.3.0-Java-17
module load SAMtools/1.18-GCC-12.3.0

echo "🧬 Indexing reference: $REFERENCE"

# Remove old index files if they exist
echo "🗑️  Cleaning previous index files (if any)..."
[[ -f "$DICT" ]] && rm -f "$DICT"
[[ -f "$FAI" ]] && rm -f "$FAI"

# Index FASTA
echo "🔧 Running samtools faidx"
samtools faidx "$REFERENCE" || { echo "❌ samtools faidx failed"; exit 1; }

# Create sequence dictionary
echo "📘 Running GATK CreateSequenceDictionary"
gatk CreateSequenceDictionary -R "$REFERENCE" || { echo "❌ GATK CreateSequenceDictionary failed"; exit 1; }

echo "✅ Reference indexing completed successfully."
