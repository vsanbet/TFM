#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=selectvars
#SBATCH --time=12:00:00
#SBATCH --mem=32G

set -euo pipefail

IN="$BSR_DIR/vcf/cohort.vcf.gz"
OUTDIR="$BSR_DIR/sel_var"
mkdir -p "$OUTDIR"

# Si el archivo ya existe, salir sin reprocesar
OUT="$OUTDIR/cohort_snps.vcf.gz"

if [[ -f "$OUT" ]]; then
	echo "El fichero $OUT ya exite. Saltando paso 4 para $SAMPLE..."
	exit 0
fi

# ====== Selección de variantes ======
# Extrae únicamente variantes de tipo SNP del VCF de cohorte
gatk SelectVariants \
  -R "$REFERENCE" \
  -V "$IN" \
  --select-type-to-include SNP \
  -O "$OUT"


echo "[INFO] SelectVariants terminado"
date
