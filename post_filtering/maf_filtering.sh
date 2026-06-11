#!/bin/bash
# =============================================================================
# Script 3: Filtrado MAF
# Uso: bash 03_maf_filter.sh <input.vcf.gz> <workdir>
# Requiere: bcftools, vcftools
# =============================================================================
set -euo pipefail

# -------- Argumentos --------
if [[ $# -ne 2 ]]; then
  echo "[ERROR] Uso: $0 <input.vcf.gz> <workdir>"
  exit 1
fi

INPUT_VCF="$1"
WORKDIR="$2"

if [[ ! -f "$INPUT_VCF" ]]; then
  echo "[ERROR] No se encuentra el VCF de entrada: $INPUT_VCF"
  exit 1
fi

MAF_THRESHOLD=0.05

OUTDIR="$WORKDIR/maf"
LOGS="$WORKDIR/logs"
mkdir -p "$OUTDIR" "$LOGS"

REPORT="$WORKDIR/logs/maf_report.txt"
echo "=======================================" > "$REPORT"
echo " INFORME FILTRADO MAF" >> "$REPORT"
echo " $(date)" >> "$REPORT"
echo " Umbral MAF: $MAF_THRESHOLD" >> "$REPORT"
echo "=======================================" >> "$REPORT"

# -------- Función: contar SNPs e individuos --------
count_stats() {
  local label="$1"
  local vcf="$2"
  local n_snps n_samples
  n_snps=$(bcftools view -H "$vcf" | wc -l)
  n_samples=$(bcftools query -l "$vcf" | wc -l)
  echo "" >> "$REPORT"
  echo "[$label]" >> "$REPORT"
  echo "  SNPs:       $n_snps" >> "$REPORT"
  echo "  Individuos: $n_samples" >> "$REPORT"
  echo "  [$label] SNPs: $n_snps | Individuos: $n_samples"
}

# ===============================
# PASO 0: Stats del input
# ===============================
echo ""
echo "[INFO] === PASO 0: VCF de entrada ==="
count_stats "INPUT (post script 2)" "$INPUT_VCF"

# ===============================
# PASO 1: Filtro MAF
# ===============================
echo ""
echo "[INFO] === PASO 1: Aplicando filtro MAF >= $MAF_THRESHOLD ==="

FINAL_VCF="$OUTDIR/final_maf_filtered.vcf.gz"

vcftools --gzvcf "$INPUT_VCF" \
         --maf "$MAF_THRESHOLD" \
         --recode --recode-INFO-all \
         --stdout 2>> "$LOGS/vcftools_maf.log" \
  | bcftools view -Oz -o "$FINAL_VCF"

bcftools index "$FINAL_VCF"

echo ""
echo "[INFO] Stats tras filtro MAF:"
count_stats "POST filtro MAF >= $MAF_THRESHOLD" "$FINAL_VCF"

# ===============================
# Distribución MAF del output (opcional pero informativo)
# ===============================
echo ""
echo "[INFO] Calculando distribución MAF del output..."

MAF_DIST="$OUTDIR/maf_distribution.txt"
vcftools --gzvcf "$FINAL_VCF" \
         --freq \
         --out "$OUTDIR/maf_freq" \
         2>> "$LOGS/vcftools_maf.log"

echo "" >> "$REPORT"
echo "[Distribución MAF — primeras 10 líneas de maf_freq.frq]" >> "$REPORT"
head -10 "$OUTDIR/maf_freq.frq" >> "$REPORT"

# ===============================
# Resumen final
# ===============================
echo ""
echo "=======================================" >> "$REPORT"
echo " FIN DEL FILTRADO MAF" >> "$REPORT"
echo " Output final: $FINAL_VCF" >> "$REPORT"
echo "=======================================" >> "$REPORT"

echo ""
echo "[INFO] ====================================="
echo "[INFO] Pipeline completado."
echo "[INFO] Output final: $FINAL_VCF"
echo "[INFO] Informe:       $REPORT"
echo "[INFO] ====================================="
date
