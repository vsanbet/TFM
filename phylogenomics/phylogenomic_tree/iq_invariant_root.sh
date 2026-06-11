#!/bin/bash
#SBATCH --account=nn8029k
#SBATCH --job-name=iqtree_snp
#SBATCH --output=tree_%j.log
#SBATCH --error=tree_%j.err
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

set -euo pipefail

# Limpiar y cargar módulos
module purge
module load StdEnv
module load IQ-TREE/2.2.2.7-gompi-2023a

# Comprobar que se pasó un archivo
if [ -z "$1" ]; then
    echo "Uso: $0 archivo.phy"
    exit 1
fi

IN_FILE="$1"
OUTDIR="$2"

mkdir -p "$OUTDIR"

PREFIX=$(basename "$IN_FILE" .phy)

# Ejecutar IQ-TREE 
iqtree2 -s "$IN_FILE" -fconst 7126166,7035362,7048997,7116492 -m TVM+F+R8 -bb 1000 -nt $SLURM_CPUS_PER_TASK -o Outgroup -pre "${OUTDIR}/${PREFIX}"
