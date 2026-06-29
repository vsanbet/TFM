#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --output=multi_%j.out
#SBATCH --error=multi_%j.err

set -euo pipefail

module purge
module load Qualimap/2.3-foss-2022b-R-4.2.2

echo "Iniciando..."

INDIV_OUT="$1"
GLOBAL_OUT="$2"

cd "$INDIV_OUT"

# Crear TSV con rutas de QC recién generadas
ls -1d */ | sed 's:/$::' | awk -v d="$PWD" '{print $1 "\t" d "/" $1}' > bam_qc.tsv

# Verificar que el TSV no esté vacío
if [[ ! -s bam_qc.tsv ]]; then
    echo "ERROR: bam_qc.tsv está vacío, los directorios QC no se han generado."
    exit 1
fi

# Ejecutar Qualimap MultiBamQC
qualimap multi-bamqc -d bam_qc.tsv -outdir "$GLOBAL_OUT"
