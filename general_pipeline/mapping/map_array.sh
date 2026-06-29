#!/bin/bash

#SBATCH --job-name=mapping_international
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --account=nn8029k
#SBATCH --ntasks=1


set -euo pipefail

SLURM_CPUS_PER_TASK=4

# ---------------------- Variables ----------------------
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
REFERENCE="${REFERENCE:-}"
OUTDIR="${OUTDIR:-}"
SAMPLES_TSV="${SAMPLES_TSV:-}"
MIN_MAPQ="${MIN_MAPQ:-20}"

if [[ -z "$REFERENCE" || -z "$OUTDIR" || -z "$SAMPLES_TSV" ]]; then
  echo "❌ Missing required environment variables: REFERENCE, OUTDIR or SAMPLES_TSV"
  exit 1
fi

source "${SCRIPT_DIR}/module.sh"

LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$SAMPLES_TSV")
SAMPLE=$(echo "$LINE" | cut -f1)
READ1=$(echo "$LINE" | cut -f2)
READ2=$(echo "$LINE" | cut -f3)

[[ ! -f "$READ1" ]] && echo "❌ Read1 not found: $READ1" && exit 1
[[ -n "$READ2" && "$READ2" != "-" && ! -f "$READ2" ]] && echo "❌ Read2 not found: $READ2" && exit 1

mkdir -p "$OUTDIR"

# ---------------------- Carpeta temporal ----------------------
# CESGA. En SAGA se queda sin espacio
#TMPDIR_LOCAL="${TMPDIR:-/tmp}"
#TMP_SAMPLE_DIR="${TMPDIR_LOCAL}/${SAMPLE}_bwa"
#mkdir -p "$TMP_SAMPLE_DIR"

#echo "📦 Using temporary directory: $TMP_SAMPLE_DIR"

# ---------------------- Mapeo ----------------------
RG="@RG\\tID:${SAMPLE}\\tSM:${SAMPLE}\\tLB:${SAMPLE}\\tPU:ILLUMINA\\tPL:ILLUMINA"
SAM="${OUTDIR}/${SAMPLE}.sam"

echo "🎯 Mapping sample: $SAMPLE"
if [[ -n "$READ2" && "$READ2" != "-" ]]; then
  bwa mem -R "$RG" -t "$SLURM_CPUS_PER_TASK" "$REFERENCE" "$READ1" "$READ2" > "$SAM"
  # debug line
  echo "🔧 Running: bwa mem -R \"$RG\" -t \"$SLURM_CPUS_PER_TASK\" \"$REFERENCE\" \"$READ1\" \"$READ2\" > \"$SAM\""

else
  bwa mem -R "$RG" -t "$SLURM_CPUS_PER_TASK" "$REFERENCE" "$READ1" > "$SAM"
fi

# ---------------------- Filtrado y ordenación ----------------------
BAM_RAW="${OUTDIR}/${SAMPLE}.filtered.bam"
BAM_SORTED="${OUTDIR}/${SAMPLE}.sorted.bam"

echo "🔎 Filtering and sorting..."
samtools view -b -q "$MIN_MAPQ" "$SAM" > "$BAM_RAW"
samtools sort "$BAM_RAW" -o "$BAM_SORTED"
samtools index "$BAM_SORTED"

rm "${OUTDIR}/${SAMPLE}.sam"
rm "${OUTDIR}/${SAMPLE}.filtered.bam"

# ---------------------- Mover a OUTDIR ----------------------
# No hace falta aquí porque no tenemos el temp.
# echo "📤 Copying final BAM and index to $OUTDIR"
# cp "$BAM_SORTED" "${OUTDIR}/${SAMPLE}.sorted.bam"
# cp "${BAM_SORTED}.bai" "${OUTDIR}/${SAMPLE}.sorted.bam.bai"

# Limpieza
#rm -rf "$TMP_SAMPLE_DIR"

echo "✅ Finished sample $SAMPLE"
