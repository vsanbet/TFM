#!/bin/bash
set -euo pipefail

# ---------------------- Parse arguments ----------------------
SAMPLES=""
REFERENCE=""
OUTDIR=""
MIN_MAPQ=30

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --samples) SAMPLES="$2"; shift 2 ;;
    --reference) REFERENCE="$2"; shift 2 ;;
    --outdir) OUTDIR="$2"; shift 2 ;;
    --min-mapq) MIN_MAPQ="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ---------------------- Validate ----------------------
if [[ -z "$SAMPLES" || -z "$REFERENCE" || -z "$OUTDIR" ]]; then
  echo "Missing required arguments."
  echo "Usage: bash run_mapping.sh --samples FILE --reference REF --outdir DIR [--min-mapq INT]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEX_SCRIPT="${SCRIPT_DIR}/index_reference.sh"
MAP_ARRAY_SCRIPT="${SCRIPT_DIR}/map_array.sh"

if [[ ! -f "$INDEX_SCRIPT" ]]; then
  echo "index_reference.sh not found at $INDEX_SCRIPT"
  exit 1
fi

if [[ ! -f "$MAP_ARRAY_SCRIPT" ]]; then
  echo "map_array.sh not found at $MAP_ARRAY_SCRIPT"
  exit 1
fi

mkdir -p "${OUTDIR}/logs"

# ---------------------- Submit reference indexing job ----------------------
echo "Launching reference indexing job..."

echo "sbatch --output=\"${OUTDIR}/logs/index_ref_%j.out\" \\"
echo "       --error=\"${OUTDIR}/logs/index_ref_%j.err\" \\"
echo "       --export=ALL,REFERENCE=\"$REFERENCE\",OUTDIR=\"$OUTDIR\",SCRIPT_DIR=\"$SCRIPT_DIR\" \\"
echo "       \"$INDEX_SCRIPT\""

INDEX_JOB_ID=$(sbatch \
  --output="${OUTDIR}/logs/index_ref_%j.out" \
  --error="${OUTDIR}/logs/index_ref_%j.err" \
  --export=ALL,REFERENCE="$REFERENCE",OUTDIR="$OUTDIR",SCRIPT_DIR="$SCRIPT_DIR" \
  "$INDEX_SCRIPT" | awk '{print $4}')

echo "Indexing job ID: $INDEX_JOB_ID"

# ---------------------- Count samples for array ----------------------
NUM_SAMPLES=$(wc -l < "$SAMPLES")
ARRAY_RANGE="0-$(($NUM_SAMPLES - 1))"

# ---------------------- Submit mapping array job with dependency ----------------------
echo "Launching mapping array job for $NUM_SAMPLES samples (afterok:$INDEX_JOB_ID)"

echo "sbatch --dependency=afterok:$INDEX_JOB_ID \\"
echo "       --array=\"$ARRAY_RANGE\" \\"
echo "       --output=\"${OUTDIR}/logs/bwa_map_%A_%a.out\" \\"
echo "       --error=\"${OUTDIR}/logs/bwa_map_%A_%a.err\" \\"
echo "       --export=ALL,SAMPLES_TSV=\"$SAMPLES\",REFERENCE=\"$REFERENCE\",OUTDIR=\"$OUTDIR\",MIN_MAPQ=\"$MIN_MAPQ\",SCRIPT_DIR=\"$SCRIPT_DIR\" \\"
echo "       \"$MAP_ARRAY_SCRIPT\""

sbatch \
  --dependency=afterok:$INDEX_JOB_ID \
  --array="$ARRAY_RANGE" \
  --output="${OUTDIR}/logs/bwa_map_%A_%a.out" \
  --error="${OUTDIR}/logs/bwa_map_%A_%a.err" \
  --export=ALL,SAMPLES_TSV="$SAMPLES",REFERENCE="$REFERENCE",OUTDIR="$OUTDIR",MIN_MAPQ="$MIN_MAPQ",SCRIPT_DIR="$SCRIPT_DIR" \
  "$MAP_ARRAY_SCRIPT"


