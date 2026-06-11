#!/usr/bin/env bash
#SBATCH --account=nn8029k
#SBATCH --job-name=cyp51A_multifasta
#SBATCH --output=logs/cyp51A_%j.out
#SBATCH --error=logs/cyp51A_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00

# ==============================================================================
# cyp51A_multifasta.sh
# Genera un multiFASTA del gen cyp51A para todas las muestras y lo alinea
# con MAFFT.
#
# Uso:
#   sbatch cyp51A_multifasta.sh -v final_maf_filtered.vcf.gz -r /ruta/Af293.fa
#   sbatch cyp51A_multifasta.sh -v final_maf_filtered.vcf.gz -r /ruta/Af293.fa -t 8 -o resultados
#
# Opciones:
#   -v  VCF multisample (obligatorio)
#   -r  Genoma de referencia FASTA indexado (obligatorio)
#   -t  Threads para MAFFT (default: CPUs asignados por SLURM)
#   -o  Directorio de salida (default: cyp51A_multifasta)
# ==============================================================================

set -euo pipefail

module purge
module purge
module load BCFtools/1.21-GCC-13.3.0
module load SAMtools/1.21-GCC-13.3.0
module load MAFFT/7.526-GCC-13.3.0-with-extensions


# --- Crear directorio de logs si no existe ---
mkdir -p logs

# --- Parámetros por defecto ---
VCF=""
REF=""
THREADS="${SLURM_CPUS_PER_TASK:-4}"   # usa los CPUs asignados por SLURM
OUTDIR="cyp51A_multifasta"
REGION="Chr_4_A_fumigatus_Af293:1783713-1785331"
GEN="cyp51A"

# --- Parsear argumentos ---
while getopts "v:r:t:o:" opt; do
    case $opt in
        v) VCF="$OPTARG" ;;
        r) REF="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        o) OUTDIR="$OPTARG" ;;
        *) echo "Uso: sbatch $0 -v vcf.gz -r ref.fa [-t threads] [-o outdir]"; exit 1 ;;
    esac
done

# --- Validar inputs ---
[[ -z "$VCF" ]] && { echo "ERROR: Especifica el VCF con -v"; exit 1; }
[[ -z "$REF" ]] && { echo "ERROR: Especifica la referencia con -r"; exit 1; }
[[ -f "$VCF" ]]  || { echo "ERROR: No encontrado: $VCF"; exit 1; }
[[ -f "$REF" ]]  || { echo "ERROR: No encontrado: $REF"; exit 1; }
[[ -f "${REF}.fai" ]] || { echo "ERROR: Referencia sin índice. Corre: samtools faidx ${REF}"; exit 1; }

for cmd in bcftools samtools mafft; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd no encontrado en PATH"; exit 1; }
done

mkdir -p "${OUTDIR}/per_sample_vcf"
mkdir -p "${OUTDIR}/per_sample_fa"

echo "=== cyp51A multiFASTA pipeline ==="
echo "Job ID:   ${SLURM_JOB_ID:-local}"
echo "VCF:      ${VCF}"
echo "REF:      ${REF}"
echo "Region:   ${REGION}"
echo "Threads:  ${THREADS}"
echo "Salida:   ${OUTDIR}"
echo "Inicio:   $(date)"
echo ""

# --------------------------------------------------------------------------
# 1. Extraer región del VCF multisample
# --------------------------------------------------------------------------

bcftools index -f "$VCF"

echo "[1/5] Extrayendo región ${GEN} del VCF multisample..."
REGION_VCF="${OUTDIR}/${GEN}_region.vcf.gz"

bcftools view \
    -r "${REGION}" \
    "${VCF}" \
    -O z -o "${REGION_VCF}"
bcftools index "${REGION_VCF}"

N_VARS=$(bcftools view "${REGION_VCF}" | grep -v "^#" | wc -l)
N_SAMPLES=$(bcftools query -l "${REGION_VCF}" | wc -l)
echo "      → ${N_VARS} variantes, ${N_SAMPLES} muestras"

# --------------------------------------------------------------------------
# 2. Separar por muestra y generar FASTA de consenso
# --------------------------------------------------------------------------
echo "[2/5] Generando FASTA de consenso por muestra..."

SAMPLES_FAILED=0
SAMPLES_OK=0

while IFS= read -r sample; do
    SAMPLE_VCF="${OUTDIR}/per_sample_vcf/${sample}_${GEN}.vcf.gz"
    SAMPLE_FA="${OUTDIR}/per_sample_fa/${sample}_${GEN}.fa"

    # VCF individual — solo sitios donde esta muestra tiene alelo alternativo
    bcftools view \
        -s "${sample}" \
        -c 1 \
        "${REGION_VCF}" \
        -O z -o "${SAMPLE_VCF}" 2>/dev/null
    bcftools index "${SAMPLE_VCF}" 2>/dev/null

    N_ALT=$(bcftools view "${SAMPLE_VCF}" 2>/dev/null | grep -v "^#" | wc -l || echo 0)

    if [ "${N_ALT}" -gt 0 ]; then
        # Muestra con variantes: aplicar sobre la referencia
        samtools faidx "${REF}" "${REGION}" | \
            bcftools consensus "${SAMPLE_VCF}" 2>/dev/null | \
            sed "s/^>.*/>${sample}/" > "${SAMPLE_FA}"
    else
        # Muestra sin variantes: secuencia idéntica a la referencia
        samtools faidx "${REF}" "${REGION}" | \
            sed "s/^>.*/>${sample}/" > "${SAMPLE_FA}"
    fi

    SAMPLES_OK=$((SAMPLES_OK + 1))

done < <(bcftools query -l "${REGION_VCF}")

echo "      → ${SAMPLES_OK} FASTAs generados (${SAMPLES_FAILED} fallidos)"

# --------------------------------------------------------------------------
# 3. Añadir la referencia como primera secuencia
# --------------------------------------------------------------------------
echo "[3/5] Añadiendo secuencia de referencia..."
REF_FA="${OUTDIR}/per_sample_fa/REFERENCE_${GEN}.fa"
samtools faidx "${REF}" "${REGION}" | sed "s/^>.*/>${REGION}_REF/" > "${REF_FA}"

# --------------------------------------------------------------------------
# 4. Concatenar multiFASTA
# --------------------------------------------------------------------------
echo "[4/5] Concatenando multiFASTA..."
MULTIFASTA="${OUTDIR}/${GEN}_all_samples.fa"

cat "${REF_FA}" > "${MULTIFASTA}"
cat "${OUTDIR}/per_sample_fa/"*"_${GEN}.fa" >> "${MULTIFASTA}"

N_SEQS=$(grep -c "^>" "${MULTIFASTA}")
echo "      → ${N_SEQS} secuencias en ${MULTIFASTA}"

echo "      Longitudes de secuencia:"
awk '/^>/{if(seq) print length(seq); seq=""} !/^>/{seq=seq$0} END{if(seq) print length(seq)}' \
    "${MULTIFASTA}" | sort | uniq -c | awk '{printf "        %s secuencias de longitud %s bp\n", $1, $2}'

# --------------------------------------------------------------------------
# 5. Alineamiento con MAFFT
# --------------------------------------------------------------------------

echo "[5/5] Alineando con MAFFT (threads: ${THREADS})..."
ALIGNED="${OUTDIR}/${GEN}_aligned.fa"

mafft \
    --auto \
    --thread "${THREADS}" \
    --reorder \
    "${MULTIFASTA}" > "${ALIGNED}" 2>"${OUTDIR}/mafft.log"

N_ALIGNED=$(grep -c "^>" "${ALIGNED}")
ALN_LEN=$(awk '/^>/{if(seq) print length(seq); seq=""} !/^>/{seq=seq$0} END{if(seq) print length(seq)}' \
    "${ALIGNED}" | sort -u | tail -1)

echo "      → Alineamiento: ${N_ALIGNED} secuencias, ${ALN_LEN} columnas"
echo "      Log MAFFT: ${OUTDIR}/mafft.log"

# --------------------------------------------------------------------------
# Resumen final
# --------------------------------------------------------------------------
echo ""
echo "=== Archivos de salida ==="
echo "  MultiFASTA sin alinear: ${MULTIFASTA}"
echo "  MultiFASTA alineado:    ${ALIGNED}"
echo "  VCFs por muestra:       ${OUTDIR}/per_sample_vcf/"
echo "  FASTAs por muestra:     ${OUTDIR}/per_sample_fa/"
echo ""
echo "Fin: $(date)"
