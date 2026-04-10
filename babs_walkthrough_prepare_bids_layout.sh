#!/bin/bash
# BABS walkthrough script — prepare BIDS study layout
# Creates a BABS-compatible BIDS study directory structure at BABS_BIDS_STUDY_DIR.
#
# Expected layout:
#   BABS_BIDS_STUDY_DIR/
#     sourcedata/raw/   (datalad subdataset with simulated BIDS data)
#     derivatives/      (empty, for BABS project output)
#
# Usage: bash babs_walkthrough_prepare_bids_layout.sh
#
# Requires BABS_BIDS_STUDY_DIR to be set (in .env or environment).

set -eux
PS4='> '

# ==============================================================================
# CONFIGURATION — edit these before running
# ==============================================================================

SIMBIDS_VERSION="0.0.3"
SIMBIDS_SIF="simbids-${SIMBIDS_VERSION}.sif"
SIMBIDS_IMAGE="docker://pennlinc/simbids:${SIMBIDS_VERSION}"

# Load custom local settings
if [ -e .env ]; then
    source .env
    echo "Configuration after loading:"
    set | grep -e SLURM_ -e BABS_ -e SCRIPT_
fi

# Validate required env vars
: "${BABS_BIDS_STUDY_DIR:?Error: BABS_BIDS_STUDY_DIR is not set}"
: "${BABS_BIDS_CONTAINER_DIR:?Error: BABS_BIDS_CONTAINER_DIR is not set}"
: "${BABS_BIDS_WORKDIR:?Error: BABS_BIDS_WORKDIR is not set}"

# ==============================================================================
# STEP 0: Create simulated BIDS data
# ==============================================================================

echo "=== Step 0: Build Singularity image ==="

mkdir -p "${BABS_BIDS_CONTAINER_DIR}"

if [ -e "${BABS_BIDS_CONTAINER_DIR}/${SIMBIDS_SIF}" ]; then
    echo "Singularity image already exists, skipping build: ${BABS_BIDS_CONTAINER_DIR}/${SIMBIDS_SIF}"
else
    echo "Building Singularity image..."
    singularity build --fakeroot "${BABS_BIDS_CONTAINER_DIR}/${SIMBIDS_SIF}" "${SIMBIDS_IMAGE}"
fi

# ==============================================================================
# STEP 1: Set up BABS BIDS study layout
# ==============================================================================

echo "=== Step 1: Set up BABS BIDS study layout ==="

echo "Creating BABS BIDS study as DataLad dataset..."
datalad create -c text2git "${BABS_BIDS_STUDY_DIR}"

echo "Generating simulated BIDS dataset..."
mkdir -p "${BABS_BIDS_WORKDIR}"
SIMBIDS_TMP=$(mktemp -d "${BABS_BIDS_WORKDIR}/simbids_XXX")
cd "${SIMBIDS_TMP}"
singularity exec -B "${SIMBIDS_TMP}" "${BABS_BIDS_CONTAINER_DIR}/${SIMBIDS_SIF}" \
    simbids-raw-mri \
        "${SIMBIDS_TMP}" \
        ds004146_configs.yaml

echo "Creating datalad dataset from simulated BIDS data..."
RAW_SRC="${SIMBIDS_TMP}/simbids"
datalad create -D "SIMBIDS simulated dataset" --force "${RAW_SRC}"
datalad save -d "${RAW_SRC}" -m "Add simulated BIDS data"

echo "Cloning simulated BIDS data as sourcedata/raw subdataset..."
RAW_DIR="${BABS_BIDS_STUDY_DIR}/sourcedata/raw"
datalad clone -d "${BABS_BIDS_STUDY_DIR}" "${RAW_SRC}" "${RAW_DIR}"
cd "${BABS_BIDS_STUDY_DIR}"
datalad get sourcedata/raw

mkdir -p "${BABS_BIDS_STUDY_DIR}/derivatives"
touch "${BABS_BIDS_STUDY_DIR}/derivatives/.gitkeep"
datalad save -d "${BABS_BIDS_STUDY_DIR}" -m "Add derivatives directory"

echo "Study layout ready at: ${BABS_BIDS_STUDY_DIR}"
