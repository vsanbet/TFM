#!/bin/bash
# =============================================================================
# Script 2: Filtrado por profundidad (DP) por muestra + missingness
# Uso: bash 02_dp_missingness.sh <input.vcf.gz> <workdir>
# Requiere: bcftools, vcftools, python3 (cyvcf2, pandas)
# =============================================================================

set -euo pipefail

module purge
module load BCFtools/1.21-GCC-13.3.0
module load SciPy-bundle/2024.05-gfbf-2024a
source /cluster/software/Miniconda3/23.10.0-1/bin/activate /cluster/projects/nn8029k/conda/vsanbet/vcf_env

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

# -------- Directorios --------
OUTDIR_DP="$WORKDIR/DP"
OUTDIR_MISS="$WORKDIR/missingness"
LOGS="$WORKDIR/logs"
mkdir -p "$OUTDIR_DP" "$OUTDIR_MISS" "$LOGS"

REPORT="$WORKDIR/logs/filtering_report.txt"
echo "=======================================" > "$REPORT"
echo " INFORME DE FILTRADO" >> "$REPORT"
echo " $(date)" >> "$REPORT"
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
count_stats "INPUT (post script 1)" "$INPUT_VCF"

# ===============================
# PASO 1: Extraer FORMAT/DP por muestra
# ===============================
echo ""
echo "[INFO] === PASO 1: Extrayendo FORMAT/DP por muestra ==="

DP_RAW="$OUTDIR_DP/DP_per_sample.txt"

# Formato [SAMPLE\tDP] — itera sobre todas las muestras por posición
bcftools query -f '[%SAMPLE\t%DP\n]' "$INPUT_VCF" \
  | grep -v '\.' \
  | grep -v '^$' > "$DP_RAW"

echo "[INFO] Valores DP extraídos: $(wc -l < "$DP_RAW") entradas"

# ===============================
# PASO 2: Calcular percentiles P5/P95 por muestra (Python)
# ===============================
echo ""
echo "[INFO] === PASO 2: Calculando percentiles P5/P95 por muestra ==="

THRESHOLDS="$OUTDIR_DP/DP_thresholds.txt"

python3 - <<EOF
import pandas as pd
import numpy as np

df = pd.read_csv("$DP_RAW", sep="\t", header=None, names=["sample", "dp"])
df["dp"] = pd.to_numeric(df["dp"], errors="coerce")
df = df.dropna()

thresholds = df.groupby("sample")["dp"].quantile([0.05, 0.95]).unstack()
thresholds.columns = ["DP_MIN", "DP_MAX"]
thresholds = thresholds.round(0).astype(int)
thresholds.to_csv("$THRESHOLDS", sep="\t")

print("[INFO] Umbrales por muestra:")
print(thresholds.to_string())
EOF

echo "" >> "$REPORT"
echo "[Umbrales DP por muestra (P5/P95)]" >> "$REPORT"
cat "$THRESHOLDS" >> "$REPORT"

source /cluster/software/Miniconda3/23.10.0-1/bin/activate /cluster/projects/nn8029k/conda/vsanbet/vcf_env
# ===============================
# PASO 3: Aplicar filtro DP por muestra (Python + cyvcf2)
# Genotipos fuera de rango → missing (./.)
# ===============================
echo ""
echo "[INFO] === PASO 3: Aplicando filtro DP por muestra ==="

DP_FILTERED="$OUTDIR_DP/DPfiltered.vcf.gz"

python3 - <<EOF
import pandas as pd
from cyvcf2 import VCF, Writer

# Cargar umbrales
thresholds = pd.read_csv("$THRESHOLDS", sep="\t", index_col=0)
dp_min = thresholds["DP_MIN"].to_dict()
dp_max = thresholds["DP_MAX"].to_dict()

vcf_in = VCF("$INPUT_VCF")
samples = vcf_in.samples

# Índice de muestra → umbrales
mins = [dp_min.get(s, 0) for s in samples]
maxs = [dp_max.get(s, float("inf")) for s in samples]

writer = Writer("$DP_FILTERED", vcf_in)

set_missing = 0
total_gt = 0

for variant in vcf_in:
    dps = variant.format("DP")
    if dps is None:
        writer.write_record(variant)
        continue

    gts = variant.genotype.array()

    for i, (dp_val, mn, mx) in enumerate(zip(dps[:, 0], mins, maxs)):
        total_gt += 1
        if dp_val < 0 or dp_val < mn or dp_val > mx:
            # Poner genotipo a missing
            gts[i, 0] = -1
            gts[i, -1] = False  # not phased
            set_missing += 1

    variant.genotype.array()[:] = gts
    writer.write_record(variant)

writer.close()
vcf_in.close()

pct = (set_missing / total_gt * 100) if total_gt > 0 else 0
print(f"[INFO] Genotipos puestos a missing por DP fuera de rango: {set_missing}/{total_gt} ({pct:.2f}%)")
EOF

bcftools index "$DP_FILTERED"

echo ""
echo "[INFO] Stats tras filtro DP:"
count_stats "POST filtro DP por muestra" "$DP_FILTERED"

module purge
module load VCFtools/0.1.16-GCC-13.2.0
module load BCFtools/1.19-GCC-13.2.0
source /cluster/software/Miniconda3/23.10.0-1/bin/activate /cluster/projects/nn8029k/conda/vsanbet/vcf_env
# ===============================
# PASO 4: Missingness por individuo (>25% missing → eliminar)
# ===============================
echo ""
echo "[INFO] === PASO 4: Missingness por individuo ==="

vcftools --gzvcf "$DP_FILTERED" \
         --missing-indv \
         --out "$OUTDIR_MISS/missing_indv" \
         2>> "$LOGS/vcftools.log"

# Individuos con >25% missing
awk 'NR>1 && $5 > 0.25 {print $1}' "$OUTDIR_MISS/missing_indv.imiss" \
  > "$OUTDIR_MISS/low_quality_indvs.txt"

N_REMOVED=$(wc -l < "$OUTDIR_MISS/low_quality_indvs.txt")
echo "[INFO] Individuos con >25% missing a eliminar: $N_REMOVED"

echo "" >> "$REPORT"
echo "[Individuos eliminados por missingness >25%]" >> "$REPORT"
echo "  Total: $N_REMOVED" >> "$REPORT"
if [[ "$N_REMOVED" -gt 0 ]]; then
  cat "$OUTDIR_MISS/low_quality_indvs.txt" >> "$REPORT"
fi

# Filtrar individuos
STEP1_VCF="$OUTDIR_MISS/step1_filtered.vcf.gz"

vcftools --gzvcf "$DP_FILTERED" \
         --remove "$OUTDIR_MISS/low_quality_indvs.txt" \
         --recode --recode-INFO-all \
         --stdout 2>> "$LOGS/vcftools.log" \
  | bcftools view -Oz -o "$STEP1_VCF"

bcftools index "$STEP1_VCF"

echo ""
echo "[INFO] Stats tras eliminar individuos con >25% missing:"
count_stats "POST filtro individuos missingness" "$STEP1_VCF"

# ===============================
# PASO 5: Missingness por posición (>10% missing → eliminar)
# ===============================
echo ""
echo "[INFO] === PASO 5: Missingness por posición ==="

FINAL_VCF="$OUTDIR_MISS/final_filtered.vcf.gz"

vcftools --gzvcf "$STEP1_VCF" \
         --max-missing 0.9 \
         --recode --recode-INFO-all \
         --stdout 2>> "$LOGS/vcftools.log" \
  | bcftools view -Oz -o "$FINAL_VCF"

bcftools index "$FINAL_VCF"

echo ""
echo "[INFO] Stats tras filtro missingness por posición (>10%):"
count_stats "POST filtro posiciones missingness" "$FINAL_VCF"

# ===============================
# Resumen final
# ===============================
echo ""
echo "=======================================" >> "$REPORT"
echo " FIN DEL FILTRADO" >> "$REPORT"
echo " Output final: $FINAL_VCF" >> "$REPORT"
echo "=======================================" >> "$REPORT"

echo ""
echo "[INFO] ====================================="
echo "[INFO] Pipeline completado."
echo "[INFO] Output final: $FINAL_VCF"
echo "[INFO] Informe:       $REPORT"
echo "[INFO] ====================================="
date
