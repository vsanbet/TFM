#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=admixture_array
#SBATCH --output=logs/admixture_K%a_%A.out
#SBATCH --error=logs/admixture_K%a_%A.err
#SBATCH --array=1-100                  # 10 K values x 10 runs = 100 jobs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=24:00:00

# =============================================================================
# ADMIXTURE array job: K=1-10, 10 runs por K, seeds diferentes
# Uso: sbatch run_admixture.sh
# =============================================================================

set -euo pipefail

module purge
module load ADMIXTURE/1.3.0

# --- Configuración -----------------------------------------------------------
INPUT="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/clusters/maf_filter"          # Archivo BED de PLINK (sin extensión .bed)
OUTDIR="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/clusters/admixture"     # Directorio de salida
THREADS=${SLURM_CPUS_PER_TASK}

# Derivar K y RUN a partir del índice del array (1-100)
# Array index 1-10  -> K=1, runs 1-10
# Array index 11-20 -> K=2, runs 1-10 ... etc.
K=$(( (SLURM_ARRAY_TASK_ID - 1) / 10 + 1 ))
RUN=$(( (SLURM_ARRAY_TASK_ID - 1) % 10 + 1 ))

# Seed única por run (reproducible pero diferente entre runs)
SEED=$((42 + (K - 1) * 10 + RUN))

# =============================================================================

echo "============================================"
echo "Job ID       : ${SLURM_JOB_ID}"
echo "Array task   : ${SLURM_ARRAY_TASK_ID}"
echo "K            : ${K}"
echo "Run          : ${RUN}"
echo "Seed         : ${SEED}"
echo "Threads      : ${THREADS}"
echo "============================================"

# Crear directorios necesarios
mkdir -p "${OUTDIR}/K${K}/run${RUN}"
mkdir -p logs

# Moverse al directorio de salida para esta combinación K/run
cd "${OUTDIR}/K${K}/run${RUN}" || exit 1

# Ruta al archivo BED (relativa al directorio original de envío)
BED_PATH="${INPUT}.bed"

# Ejecutar ADMIXTURE
admixture \
    --seed=${SEED} \
    -j${THREADS} \
    --cv=10 \
    "${BED_PATH}" \
    ${K} \
    | tee admixture_K${K}_run${RUN}.log

# Renombrar outputs para incluir K y run en el nombre
BASENAME=$(basename "${INPUT}" .bed)

if [ -f "${BASENAME}.${K}.Q" ]; then
    mv "${BASENAME}.${K}.Q"   "${BASENAME}_K${K}_run${RUN}.Q"
    mv "${BASENAME}.${K}.P"   "${BASENAME}_K${K}_run${RUN}.P"
    echo "Outputs renombrados correctamente."
else
    echo "ERROR: No se encontraron archivos de salida para K=${K} run=${RUN}" >&2
    exit 1
fi

# Extraer CV error del log y guardarlo en un archivo resumen
CV=$(grep "CV error" admixture_K${K}_run${RUN}.log | awk '{print $NF}')
echo "K=${K}  run=${RUN}  seed=${SEED}  CV=${CV}" \
    >> "${OUTDIR}/cv_errors.txt"

echo "Finalizado K=${K} run=${RUN} con CV=${CV}"
