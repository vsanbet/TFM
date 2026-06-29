#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=genoGVCFs
#SBATCH --time=48:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4

set -euo pipefail

GVCF_DIR="$BSR_DIR/gvcf"
OUTDIR="$BSR_DIR/vcf"
mkdir -p "$OUTDIR"



# Si el VCF final ya existe, salir sin reprocesar
OUT="$OUTDIR/cohort.vcf.gz"

if [[ -f "$OUT" ]]; then
	echo "El fichero $OUT ya existe. Saltando paso 3 para $SAMPLE..."
	exit 0
fi

# ====== Construcción de argumentos -V para GATK ======
# Convierte cada archivo *.g.vcf.gz en un argumento "-V archivo'
VARGS=$(ls "$GVCF_DIR"/*.g.vcf.gz | awk '{print "-V "$1}')


# ====== Paso 1: Combinar GVCFs ======
# Une todos los GVCF individuales en un GVCF de cohorte
gatk CombineGVCFs \
  -R "$REFERENCE" \
  $VARGS \
  -O "$GVCF_DIR/cohort.g.vcf.gz"


# ====== Paso 2: Genotipado conjunto ======
# Convierte el GVCF de cohorte en un VCF final con genotipos
gatk GenotypeGVCFs \
  -R "$REFERENCE" \
  -V "$GVCF_DIR/cohort.g.vcf.gz" \
  -O "$OUT"


echo "[INFO] CombineGVCFs y GenotypeGVCFs terminado"
date
