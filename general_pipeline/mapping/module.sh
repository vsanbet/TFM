#!/bin/bash

# ==============================================================================
# SAGA_modules.sh
# Load required modules for BWA mapping at SAGA
# ==============================================================================

set -euo pipefail

echo "Loading modules for BWA mapping at SAGA..."
module purge

# Load bioinformatic tools
module load BWA/0.7.18-GCCcore-12.3.0
module load SAMtools/1.18-GCC-12.3.0

echo "Modules successfully loaded"
