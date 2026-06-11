#!/bin/bash

#SBATCH --account=nn8029k
#SBATCH --job-name=mapeo_outgroup
#SBATCH --output=mapeo_outgroup_%j.out
#SBATCH --error=mapeo_outgroup_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=08:00:00
#SBATCH --mem-per-cpu=8G

set -euo pipefail

# ---------------------- Variables ----------------------
REFERENCE="/cluster/projects/nn8029k/PloidYeast/ValeriaS/backup/data_ordenadir/FungiDB/Aspfu1_AssemblyScaffolds_Repeatmasked.fasta"
OUTDIR="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/outgroup/mapeo"
SAMPLE="Outgroup"
READ1="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/outgroup/fastq/SRR11363406_1.fastq"
READ2="/cluster/projects/nn8029k/PloidYeast/ValeriaS/resultados_aad/outgroup/fastq/SRR11363406_2.fastq"
THREADS=4

mkdir -p "$OUTDIR"

# ---------------------- Módulos ----------------------
module purge
module load BWA/0.7.18-GCCcore-12.3.0
module load SAMtools/1.18-GCC-12.3.0

# ---------------------- Preparar referencia (si hace falta) ----------------------
if [[ ! -f "${REFERENCE}.fai" ]]; then
  echo "[INFO] Indexing reference with samtools faidx"
  samtools faidx "$REFERENCE"
fi

DICT="${REFERENCE%.*}.dict"
if [[ ! -f "$DICT" ]]; then
  echo "[INFO] Creating sequence dictionary for GATK"
  gatk CreateSequenceDictionary -R "$REFERENCE"
fi

# ---------------------- Read Group ----------------------
RG="@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:${SAMPLE}\tPL:ILLUMINA"

# ---------------------- Mapeo y BAM ordenado ----------------------
BAM_SORTED="${OUTDIR}/${SAMPLE}.sorted.bam"

if [[ ! -f "$BAM_SORTED" ]]; then

	echo "[INFO] Mapping sample: $SAMPLE"

	bwa mem -R "$RG" -t "$THREADS" "$REFERENCE" "$READ1" "$READ2" | \
  	samtools view -b -@ "$THREADS" - | \
  	samtools sort -@ "$THREADS" -o "$BAM_SORTED"

	samtools index "$BAM_SORTED"

	echo "[INFO] BAM final: $BAM_SORTED"
fi

module purge
module load StdEnv
module load GATK/4.5.0.0-GCCcore-12.3.0-Java-17

# ---------------------- Variant Calling (outgroup) ----------------------
VCF_OUT="${OUTDIR}/${SAMPLE}.vcf.gz"

echo "[INFO] Running GATK HaplotypeCaller"

gatk HaplotypeCaller \
  -R "$REFERENCE" \
  -I "$BAM_SORTED" \
  -O "$VCF_OUT"

echo "✅ Pipeline completado correctamente"
echo "   BAM: $BAM_SORTED"
echo "   VCF: $VCF_OUT"
