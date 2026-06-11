#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=unite_mapping
#SBATCH --output=logs_merge/%x_%A_%a.out
#SBATCH --error=logs_merge/%x_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=05:00:00
#SBATCH --mem-per-cpu=2GB

set -euo pipefail

# --------------------------------------------
# 1. ARGUMENTOS
# --------------------------------------------
SAMPLES_TSV="$1"
IN_DIR="$2"
OUT_DIR="$3"

module purge
module load SAMtools/1.18-GCC-12.3.0

mkdir -p "$OUT_DIR" "logs_merge"

# --------------------------------------------
# 2. AUTODETECTAR NÚMERO DE LÍNEAS Y CONFIG ARRAY
# --------------------------------------------
TOTAL_LINES=$(wc -l < "$SAMPLES_TSV")

# Líneas 2 → N son las que queremos procesar
FIRST_TASK=1
LAST_TASK=$((TOTAL_LINES - 1))

# Si no estamos dentro de un SLURM array,
# relanzamos este mismo script como array job
if [ -z "${SLURM_ARRAY_TASK_ID+x}" ]; then
    echo "→ Relanzando como array job: $FIRST_TASK-$LAST_TASK"
    sbatch --array=${FIRST_TASK}-${LAST_TASK} "$0" "$SAMPLES_TSV" "$IN_DIR" "$OUT_DIR"
    exit 0
fi

# --------------------------------------------
# 3. OBTENER LA LÍNEA CORRECTA (Task 1 = línea 2)
# --------------------------------------------
LINE_NUMBER=$((SLURM_ARRAY_TASK_ID + 1))
LINE=$(sed -n "${LINE_NUMBER}p" "$SAMPLES_TSV")

SAMPLE_NAME=$(echo "$LINE" | cut -f1)
BIOINFONAME=$(echo "$LINE" | cut -f2)
BIOSAMPLE=$(echo "$LINE" | cut -f3)
ILLUMINA_ACCESSION=$(echo "$LINE" | cut -f4)

echo "▶ TASK $SLURM_ARRAY_TASK_ID → procesando línea $LINE_NUMBER"
echo "  SAMPLE: $SAMPLE_NAME | BIOSAMPLE: $BIOSAMPLE | BIOINFONAME: $BIOINFONAME"

# --------------------------------------------
# 4. AGRUPAR LÍNEAS CON EL MISMO BIOSAMPLE
# --------------------------------------------
GROUP_LINES=("$LINE")

i=$((SLURM_ARRAY_TASK_ID + 2))

while [ $i -le $TOTAL_LINES ]; do
    NEXT_LINE=$(sed -n "${i}p" "$SAMPLES_TSV")
    NEXT_BIOSAMPLE=$(echo "$NEXT_LINE" | cut -f3)

    if [ "$NEXT_BIOSAMPLE" == "$BIOSAMPLE" ]; then
        GROUP_LINES+=("$NEXT_LINE")
        ((i++))
    else
        break
    fi
done

# --------------------------------------------
# 5. EVITAR DUPLICADOS (solo primer task del grupo)
# --------------------------------------------
if [ $SLURM_ARRAY_TASK_ID -gt 1 ]; then
    PREV_LINE=$(sed -n "$((LINE_NUMBER - 1))p" "$SAMPLES_TSV")
    PREV_BIOSAMPLE=$(echo "$PREV_LINE" | cut -f3)

    if [ "$PREV_BIOSAMPLE" == "$BIOSAMPLE" ]; then
        echo "→ Task $SLURM_ARRAY_TASK_ID salta: grupo ya procesado."
        exit 0
    fi
fi

# --------------------------------------------
# 6. COLECTAR BAMS
# --------------------------------------------
BAMS=()
FINAL_BIOINFONAME=""

for L in "${GROUP_LINES[@]}"; do
    ACC=$(echo "$L" | cut -f4)
    L_BIOINFONAME=$(echo "$L" | cut -f2)

    BAM="${IN_DIR}/${ACC}.sorted.bam"
    if [ ! -f "$BAM" ]; then
        echo "ERROR: BAM no encontrado: $BAM"
        exit 1
    fi

    BAMS+=("$BAM")
    FINAL_BIOINFONAME="$L_BIOINFONAME"
done

# --------------------------------------------
# 7. MERGE FINAL
# --------------------------------------------
OUT_BAM="${OUT_DIR}/${FINAL_BIOINFONAME}.sorted.bam"
NUM_BAMS=${#BAMS[@]}

if [ "$NUM_BAMS" -eq 1 ]; then
    echo "Solo un BAM para BIOSAMPLE $BIOSAMPLE. No se hace merge."
    # Opcional: dejar el BAM original como OUT_BAM o copiarlo
    # cp "${BAMS[0]}" "$OUT_BAM"
else
    echo "Merge de $NUM_BAMS BAMs para BIOSAMPLE $BIOSAMPLE → $OUT_BAM"
    samtools merge -o "$OUT_BAM" "${BAMS[@]}"
fi

# --------------------------------------------
# 8. COMPROBACIÓN DEL MERGE
# --------------------------------------------
echo "→ Verificando merge con samtools quickcheck..."
if samtools quickcheck -v "$OUT_BAM"; then
    echo "✔ BAM válido: $OUT_BAM"
else
    echo "❌ ERROR: BAM corrupto o incompleto: $OUT_BAM"
    exit 1
fi

echo "→ Resumen de lecturas con flagstat:"
samtools flagstat "$OUT_BAM"
