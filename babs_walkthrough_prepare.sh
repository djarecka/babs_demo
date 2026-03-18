#!/bin/bash
# BABS walkthrough script
# Based on: https://pennlinc-babs.readthedocs.io/en/stable/walkthrough.html
#
# Usage: bash babs_walkthrough.sh
#
# Customize the variables in the CONFIGURATION section below before running.

set -eux
PS4='> '


# ==============================================================================
# CONFIGURATION — edit these before running
# ==============================================================================

SIMBIDS_VERSION="0.0.3"
SIMBIDS_SIF="simbids-${SIMBIDS_VERSION}.sif"
SIMBIDS_IMAGE="docker://pennlinc/simbids:${SIMBIDS_VERSION}"
CONTAINER_NAME="simbids-0-0-3"

# Load custom local setting (potentially Yarik specific)
if [ -e .env ]; then
    source .env
    echo "Configuration after loading:"
    set | grep -e SLURM_ -e BABS_ -e SCRIPT_
fi


DEMO_PREP_DIR="${BABS_WORKDIR}/babs_walkthrough_preparation"
echo "demo prep dir" $DEMO_PREP_DIR
mkdir -p "${DEMO_PREP_DIR}"
cd "${DEMO_PREP_DIR}"



# ==============================================================================
# STEP 0: Create testing BIDS data
# ==============================================================================

echo "=== Step 0: Create simulated BIDS dataset ==="

echo "Building Singularity image..."
singularity build --fakeroot "${SIMBIDS_SIF}" "${SIMBIDS_IMAGE}"

echo "Generating simulated BIDS dataset..."
singularity exec -B "${DEMO_PREP_DIR}" "${SIMBIDS_SIF}" \
    simbids-raw-mri \
        "${DEMO_PREP_DIR}" \
        ds004146_configs.yaml

echo "Converting to DataLad dataset..."
cd "${DEMO_PREP_DIR}/simbids"
datalad create -D "SIMBIDS simulated dataset" -d . --force
datalad save

