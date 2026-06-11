#!/bin/bash
#SBATCH --job-name=index_ref
#SBATCH --account=nn8029k
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G

echo "🔧 SLURM job started: Index reference"

set -euo pipefail

# ---------------------- Leer variables de entorno ----------------------
REFERENCE="${REFERENCE:-}"
OUTDIR="${OUTDIR:-}"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ---------------------- Depuración útil ----------------------
echo "📌 Starting index_reference.sh"
echo "🧬 REFERENCE: $REFERENCE"
echo "📁 OUTDIR: $OUTDIR"
echo "📂 SCRIPT_DIR: $SCRIPT_DIR"

# ---------------------- Validaciones ----------------------
if [[ -z "$REFERENCE" || -z "$OUTDIR" ]]; then
  echo "❌ Missing required variables: REFERENCE and/or OUTDIR"
  exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
  echo "❌ Reference file not found: $REFERENCE"
  exit 1
fi

mkdir -p "$OUTDIR/logs"
cd "$OUTDIR/logs"

# ---------------------- Cargar módulos ----------------------
if [[ ! -f "$SCRIPT_DIR/module.sh" ]]; then
  echo "❌ module.sh not found in $SCRIPT_DIR"
  exit 1
fi

source "$SCRIPT_DIR/module.sh"

# ---------------------- Reindexar todo desde cero ----------------------
echo "🧹 Removing previous index files (if any)..."
rm -f "${REFERENCE}".{amb,ann,bwt,pac,sa,fai,dict}

echo "📦 Running bwa index..."
bwa index "$REFERENCE"

echo "📦 Running samtools faidx..."
samtools faidx "$REFERENCE"

echo "✅ Indexing completed successfully for: $REFERENCE"
