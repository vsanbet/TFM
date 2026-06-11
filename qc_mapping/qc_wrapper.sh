#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --time=00:05:00
#SBATCH --output=wrapper_%j.out
#SBATCH --error=wrapper_%j.err
#SBATCH --mem-per-cpu=8G

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "USO: $0 input_file.tsv out_individual out_global"
    exit 1
fi

IN_FILE="$1"
INDIV_OUT="$2"
GLOBAL_OUT="$3"

# Número de líneas del TSV
N=$(wc -l < "$IN_FILE")

echo "Lanzando array de 1 a $N tareas…"

ARRAY_JOB=$(sbatch --array=1-$N qc_array.sh "$IN_FILE" "$INDIV_OUT" | awk '{print $4}')
echo " → JOB ARRAY ID = $ARRAY_JOB"

# NO generar bam_qc.tsv aquí
# Se genera dentro de qc_multi.sh

sbatch --dependency=afterok:$ARRAY_JOB qc_multi.sh "$INDIV_OUT" "$GLOBAL_OUT"

