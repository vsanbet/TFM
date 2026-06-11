#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=hapcall
#SBATCH --time=08:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4

set -euo pipefail


# ====== Obtener la lista de BAM recalibrados ======
# Lee todos los BAM recalibrados (*.recal.bam), los ordena
# y los guarda en un array (BAM_LIST)
mapfile -t BAM_LIST < <(ls "$BSR_DIR"/*.recal.bam | sort)

# Selecciona el BAM correspondiente al SLURM_ARRAY_TASK_ID
BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
SAMPLE=$(basename "$BAM" .recal.bam)

OUTDIR="$BSR_DIR/gvcf"
mkdir -p "$OUTDIR"


# Si el archivo de salida ya existe, salir sin reprocesar
OUT="$OUTDIR/${SAMPLE}.g.vcf.gz"

if [[ -f "$OUT" ]]; then
	echo "El fichero $OUT ya existe. Saltando el paso 2 para $SAMPLE..."
	exit 0
fi

# ====== Llamada de variantes con HaplotypeCaller ======
# -ERC GVCF: modo GVCF para joint genotyping posterior

gatk HaplotypeCaller \
  -R "$REFERENCE" \
  -I "$BAM" \
  -O "$OUT" \
  -ERC GVCF \
  --sample-ploidy 1


echo "[INFO] HaplotypeCaller terminado"
date
