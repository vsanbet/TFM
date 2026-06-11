#!/bin/bash

# ==============================================================================
# CESGA_modules.sh
# Load required modules for BWA mapping at CESGA (cesga/2020 environment)
# ==============================================================================

# set -euo pipefail

# echo "📦 Loading modules for BWA mapping at CESGA..."
# module purge

# load env
# module load cesga/2020

# Load required compilers/toolchains
# module load gcccore/12.3.0

# Load bioinformatics tools
# module load bwa/0.7.17
# module load samtools/1.19

# echo "✅ Modules successfully loaded"

# ==============================================================================
# SAGA_modules.sh
# Load required modules for BWA mapping at SAGA
# ==============================================================================

set -euo pipefail

echo "📦 Loading modules for BWA mapping at SAGA..."
module purge

# Load bioinformatic tools
module load BWA/0.7.18-GCCcore-12.3.0
module load SAMtools/1.18-GCC-12.3.0

echo "✅ Modules successfully loaded"
