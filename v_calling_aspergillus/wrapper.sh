#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/module.sh"

# -------- Parse args --------
while [[ $# -gt 0 ]]; do
  case $1 in
    --samples) SAMPLES_TSV="$2"; shift 2;;
    --reference) REFERENCE="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    *) echo "❌ Unknown parameter $1"; exit 1;;
  esac
done

if [[ -z "${SAMPLES_TSV:-}" || -z "${REFERENCE:-}" || -z "${WORKDIR:-}" ]]; then
  echo "Usage: bash wrapper.sh --samples samples.tsv --reference ref.fa --workdir DIR"
  exit 1
fi

LOG_DIR="$WORKDIR/logs"
mkdir -p "$LOG_DIR"

echo "[INFO] Starting pipeline"
echo "[INFO] Samples TSV : $SAMPLES_TSV"
echo "[INFO] Reference   : $REFERENCE"
echo "[INFO] Workdir     : $WORKDIR"
echo "[INFO] Script dir  : $SCRIPT_DIR"
date

# -------- Step 0: index reference --------
INDEX_JOB_ID=$(sbatch \
  --output="$LOG_DIR/step00_%j.out" \
  --error="$LOG_DIR/step00_%j.err" \
  "$SCRIPT_DIR/index_reference.sh" "$REFERENCE" | awk '{print $NF}')

echo "[INFO] Submitted index job with ID: $INDEX_JOB_ID"

# -------- Count samples (skip header) --------
NUM_SAMPLES=$(tail -n +2 "$SAMPLES_TSV" | wc -l)
ARRAY_RANGE="1-$NUM_SAMPLES"

# -------- Step 1: BQSR --------
BQSR_JOB_ID=$(sbatch \
  --dependency=afterok:$INDEX_JOB_ID \
  --array=$ARRAY_RANGE \
  --output="$LOG_DIR/step01_%A_%a.out" \
  --error="$LOG_DIR/step01_%A_%a.err" \
  --export=ALL,SAMPLES_TSV="$SAMPLES_TSV",REFERENCE="$REFERENCE",BSR_DIR="$WORKDIR/bsr_dir" \
  "$SCRIPT_DIR/01_base_recalibrator.sh" | awk '{print $NF}')
echo "[INFO] Submitted BQSR job with ID: $BQSR_JOB_ID"


# -------- Step 2: HaplotypeCaller --------
HC_JOB_ID=$(sbatch \
  --dependency=afterok:$BQSR_JOB_ID \
  --array=$ARRAY_RANGE \
  --output="$LOG_DIR/step02_%A_%a.out" \
  --error="$LOG_DIR/step02_%A_%a.err" \
  --export=ALL,REFERENCE="$REFERENCE",BSR_DIR="$WORKDIR/bsr_dir" \
  "$SCRIPT_DIR/02_hapcaller.sh" | awk '{print $NF}')

echo "[INFO] Submitted Haplotype Caller job with ID: $HC_JOB_ID"


# -------- Step 3: GenotypeGVCFs --------
GVCF_JOB_ID=$(sbatch \
  --dependency=afterok:$HC_JOB_ID \
  --output="$LOG_DIR/step03_%A.out" \
  --error="$LOG_DIR/step03_%A.err" \
  --export=ALL,REFERENCE="$REFERENCE",BSR_DIR="$WORKDIR/bsr_dir" \
  "$SCRIPT_DIR/03_genotypegvcf.sh" | awk '{print $NF}')

echo "[INFO] Submitted GVCF job with ID: $GVCF_JOB_ID"


# -------- Step 4: SelectVariants --------
SEL_VAR_JOB_ID=$(sbatch \
  --dependency=afterok:$GVCF_JOB_ID \
  --output="$LOG_DIR/step04_%A.out" \
  --error="$LOG_DIR/step04_%A.err" \
  --export=ALL,REFERENCE="$REFERENCE",BSR_DIR="$WORKDIR/bsr_dir" \
  "$SCRIPT_DIR/04_selectvariants.sh" | awk '{print $NF}')

echo "[INFO] Submitted Select Variants job with ID: $SEL_VAR_JOB_ID"

# === Step 05: FilterVariants ===
FIL_VAR_JOB_ID=$(sbatch \
  --dependency=afterok:$SEL_VAR_JOB_ID \
  --output=$LOG_DIR/step05_%A.out \
  --error=$LOG_DIR/step05_%A.err \
  --export=ALL,REFERENCE="$REFERENCE",BSR_DIR="$WORKDIR/bsr_dir" \
  "$SCRIPT_DIR/05_filtervariants.sh" | awk '{print $NF}')
echo "[INFO] Submitted Filter Variants job with ID: $FIL_VAR_JOB_ID"
