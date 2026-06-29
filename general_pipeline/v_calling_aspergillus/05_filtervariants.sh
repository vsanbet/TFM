#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=filtervars
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --output=logs/filter_var_%A.out
#SBATCH --error=logs/filter_var_%A.err

set -euo pipefail

echo "[INFO] Starting VariantFiltration"

REFERENCE="${REFERENCE}"
BSR_DIR="${BSR_DIR}"

IN_VCF="$BSR_DIR/sel_var/cohort_snps.vcf.gz"
OUTDIR="$BSR_DIR/filtered"
mkdir -p "$OUTDIR"

OUT_VCF="$OUTDIR/cohort_snps.filtered.vcf.gz"

# ===============================
# Skip if output exists
# ===============================
if [[ -f "$OUT_VCF" ]]; then
  echo "El fichero $OUT_VCF ya existe. Saltando paso 5 para $SAMPLE."
  exit 0
fi

# ===============================
# VariantFiltration (hard filters)
# Haploid-aware thresholds
# ===============================
gatk VariantFiltration \
  -R "$REFERENCE" \
  -V "$IN_VCF" \
  -O "$OUT_VCF" \
  --filter-name "afum" \
  --filter-expression "QUAL < 30.0 || QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0 || SOR > 3.0"


# ===============================
# Quedarse solo con PASS
# ===============================
PASS_VCF="$OUTDIR/cohort_snps_pass.filtered.vcf.gz"

gatk SelectVariants \
  -R "$REFERENCE" \
  -V "$OUT_VCF" \
  -O "$PASS_VCF" \
  --exclude-filtered

gatk IndexFeatureFile -I "$PASS_VCF"

echo "[INFO] VariantFiltration terminado"
date
