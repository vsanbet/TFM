#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=bqsr
#SBATCH --time=08:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4

set -euo pipefail

LINE=$(tail -n +2 "$SAMPLES_TSV" | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE=$(echo "$LINE" | cut -f1)
BAM=$(echo "$LINE" | cut -f2)

mkdir -p "$BSR_DIR"



# Si el BAM de salida ya existe, salir sin hacer nada
OUT_BAM="$BSR_DIR/${SAMPLE}.recal.bam"

if [[ -f "$OUT_BAM" ]]; then
	echo "EL fichero $OUT_BAM ya existe. Saltando el paso 1 para $SAMPLE..."
	exit 0
fi

# ====== Paso 1: Base Quality Score Recalibration (BQSR) ======
# Genera una tabla de recalibración usando sitios conocidos

gatk BaseRecalibrator \
  -I "$BAM" \
  -R "$REFERENCE" \
  --known-sites /cluster/projects/nn8029k/PloidYeast/ValeriaS/backup/data_ordenadir/FungiDB/FungiDB.renamed.vcf.gz \
  -O "$BSR_DIR/${SAMPLE}.table"


# ====== Paso 2: Aplicar la recalibración ======
# Aplica la tabla de recalibración al BAM original

gatk ApplyBQSR \
  -R "$REFERENCE" \
  -I "$BAM" \
  --bqsr-recal-file "$BSR_DIR/${SAMPLE}.table" \
  -O "$OUT_BAM"


echo "[INFO] BaseRecalibrator y ApplyBSQR terminados."
date
