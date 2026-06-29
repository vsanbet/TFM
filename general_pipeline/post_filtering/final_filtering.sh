#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=dp_missingness
#SBATCH --output="logs/dp_%A_%a.out" \
#SBATCH --error="logs/dp_%A_%a.err" \
#SBATCH --time=05:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4

set -euo pipefail

module purge
module load BCFtools/1.22-GCC-14.2.0

COHORT="$1"
WORKDIR="$2"
LOGS="$WORKDIR/logs"

mkdir -p "$LOGS"

# -------- Revisar variables exportadas --------
if [[ -z "${COHORT:-}" || -z "${WORKDIR:-}" ]]; then
  echo "[ERROR] SAMPLES_GVCF or WORKDIR not set "
  exit 1
fi

OUTDIR="$WORKDIR/DP"
mkdir -p "$OUTDIR"

DP_FILE="${OUTDIR}/DP_values.txt"

# ------------------------------
# Extraer DP (FORMAT) con bcftools
# ------------------------------
bcftools query -f '%DP\n' "$COHORT" \
  | grep -v '\.' \
  | sort -n \
  | uniq > "$DP_FILE"

# ------------------------------
# Calcular percentiles 5% y 95%
# ------------------------------
N=$(wc -l < "$DP_FILE")

if [[ "$N" -eq 0 ]]; then
  echo "[ERROR] No DP values found for $SAMPLE"
  exit 1
fi

p5=$(( (N * 5 + 99) / 100 ))
p95=$(( (N * 95 + 99) / 100 ))

DP_MIN=$(sed -n "${p5}p" "$DP_FILE")
DP_MAX=$(sed -n "${p95}p" "$DP_FILE")

echo "[INFO] DP_min=$DP_MIN, DP_max=$DP_MAX"

# ------------------------------
# Filtrar VCF por FORMAT/DP
# ------------------------------
FILTERED_VCF="${OUTDIR}/DPfiltered.vcf.gz"

bcftools filter \
  -i "FORMAT/DP >= $DP_MIN && FORMAT/DP <= $DP_MAX" \
  "$COHORT" \
  -Oz -o "$FILTERED_VCF"

bcftools index "$FILTERED_VCF"

echo "[INFO] Filtered VCF generated:"
echo "       $FILTERED_VCF"

module purge
module load VCFtools/0.1.16-GCC-13.2.0

OUTDIR2="$WORKDIR/missingness"
mkdir -p "$OUTDIR2"

# -------- Missingness por individuo --------
vcftools --gzvcf "$FILTERED_VCF" --missing-indv --out "${OUTDIR2}/missing_indv"

# -------- Identificar individuos con >25% missing --------
awk '$5 > 0.25 {print $1}' "${OUTDIR2}/missing_indv.imiss" > "${OUTDIR2}/low_quality_indvs.txt"

# -------- Filtrar individuos --------
vcftools --gzvcf "$FILTERED_VCF" \
         --remove "${OUTDIR2}/low_quality_indvs.txt" \
         --recode --recode-INFO-all --out "${OUTDIR2}/step1_filtered"

# -------- Filtrar posiciones con >10% missing --------
vcftools --vcf "${OUTDIR2}/step1_filtered.recode.vcf" \
         --max-missing 0.9 \
         --recode --recode-INFO-all \
         --out "${OUTDIR2}/final_filtered"

echo "[INFO] Filtering done. Final VCF:"
echo "       ${OUTDIR2}/final_filtered.recode.vcf"

