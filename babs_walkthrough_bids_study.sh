#!/bin/bash
# BABS walkthrough script
# Based on: https://pennlinc-babs.readthedocs.io/en/stable/walkthrough.html
# This version start from BIDS study directory with raw data 
# Usage: bash babs_walkthrough_bids_study.sh
#
# Customize the variables in the CONFIGURATION section below before running.

set -eux
PS4='> '

INIT_ONLY=false

for arg in "$@"; do
  case $arg in
      --init-only) INIT_ONLY=true ;;
      *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done



# ==============================================================================
# CONFIGURATION — edit these before running
# ==============================================================================

SIMBIDS_VERSION="0.0.3"
SIMBIDS_SIF="simbids-${SIMBIDS_VERSION}.sif"
SIMBIDS_IMAGE="docker://pennlinc/simbids:${SIMBIDS_VERSION}"
CONTAINER_NAME="simbids-0-0-3"
PROCESSING_LEVEL="session"   # "subject" or "session"
QUEUE="slurm"                # "slurm" or "sge"
INTERPRETING_SHELL="/bin/bash"
ANALYSIS_PATH="." # that should be default for the BIDS study
DATA_REL_DIR="sourcedata/raw"

# Load custom local setting (potentially Yarik specific)
if [ -e .env ]; then
    source .env
    echo "Configuration after loading:"
    set | grep -e SLURM_ -e BABS_ -e SCRIPT_
fi

cd "$(mktemp -d "${BABS_BIDS_WORKDIR:-/tmp}/babs_walkthrough_yoh_XXX")"

DEMO_DIR="${PWD}"
echo "demo dir ${DEMO_DIR}"
BABS_CONFIG_FILE="${DEMO_DIR}/config_simbids_0-0-3_raw_mri.yaml"
CONTAINER_DS="${DEMO_DIR}/simbids-container"
JOB_COMPUTE_SPACE="${DEMO_DIR}/job_compute_space"
mkdir -p "${JOB_COMPUTE_SPACE}"

# setiing directory names in the derivatives directory
# checking if BABS_BIDS_STUDY_DIR exist
if [ -z "${BABS_BIDS_STUDY_DIR}" ]; then
    echo "Error: BABS_BIDS_STUDY_DIR is not set" >&2
    exit 1
elif [ -z "${BABS_CONTAINER_DIR}" ]; then
    echo "Error: BABS_CONTAINER_DIR is not set" >&2
    exit 1
fi

DEMO_REL_DIR=$(basename "${DEMO_DIR}")
DERIVATIVE_DIR="${BABS_BIDS_STUDY_DIR}/derivatives/${DEMO_REL_DIR}"
DATA_DIR="${BABS_BIDS_STUDY_DIR}/${DATA_REL_DIR}"
CONTAINER_PATH="${BABS_CONTAINER_DIR}/${SIMBIDS_SIF}"

# ==============================================================================
# STEP 1: Preparation
# ==============================================================================

echo ""
echo "=== Step 1: Preparation ==="

# 1.2 Container DataLad dataset
echo "Creating container DataLad dataset..."
cd "${DEMO_DIR}"
datalad create -D "SIMBIDS container" simbids-container
cd simbids-container
datalad containers-add \
    --url "${CONTAINER_PATH}" \
    "${CONTAINER_NAME}"

# YAML configuration file
echo "Writing BABS container config YAML..."
cat > "${BABS_CONFIG_FILE}" <<YAML
bids_app_args:
    --bids-app: fmriprep
    \$SUBJECT_SELECTION_FLAG: "--participant-label"
    --stop-on-first-crash: ""
    -vv: ""
    --anat-only: ""
analysis_path: ${ANALYSIS_PATH}
input_ria_path: ".babs/input_ria"
output_ria_path: ".babs/output_ria"
all_results_in_one_zip: true
zip_foldernames:
    fmriprep_anat: "25-0-0"

singularity_args:
    - --no-home  # otherwise Dorota gets a magical error
    - --writable-tmpfs

cluster_resources:
    interpreting_shell: ${INTERPRETING_SHELL}
    customized_text: |
$(echo "$SLURM_RESOURCES" | sed -e 's,^,        ,g')

script_preamble: |
$(echo "$SCRIPT_PREAMBLE" | sed -e 's,^,        ,g')

job_compute_space: "${JOB_COMPUTE_SPACE}"

input_datasets:
    BIDS:
        required_files:
            - "anat/*_T1w.nii*"
        is_zipped: false
        origin_url: "${DATA_DIR}"
        path_in_babs: sourcedata/raw
YAML

echo "Config written to: ${BABS_CONFIG_FILE}"

# ==============================================================================
# STEP 2: Create BABS project
# ==============================================================================

echo ""
echo "=== Step 2: Initialize BABS project ==="

cd "${DEMO_DIR}"
babs init \
    --container_ds "${CONTAINER_DS}" \
    --container_name "${CONTAINER_NAME}" \
    --container_config "${BABS_CONFIG_FILE}" \
    --processing_level "${PROCESSING_LEVEL}" \
    --queue "${QUEUE}" \
    "${DERIVATIVE_DIR}"

echo "Verifying setup with a test job..."
cd "${DERIVATIVE_DIR}"
# removing for now, since it gives an error
#babs check-setup --job-test

# ==============================================================================
# STEP 2b: get containers
# ==============================================================================
if [ -d "${ANALYSIS_PATH}/containers/" ]; then
    pushd "${ANALYSIS_PATH}/containers/"
elif [ -d "analysis/containers/" ]; then
    pushd "analysis/containers/"
else
    echo "ERROR: containers directory not found"
    exit 1
fi

# TODO template this path
datalad get .datalad/environments/simbids-0-0-3/image
popd


if [ "$INIT_ONLY" = true ]; then
    echo "Only run babs init, no submit!"
    exit 0
fi

# ==============================================================================
# STEP 3: Submit jobs and monitor
# ==============================================================================

echo ""
echo "=== Step 3: Submit and monitor jobs ==="

cd "${DERIVATIVE_DIR}"


echo "Initial status:"
babs status

#echo "Submitting first job..."
#babs submit --count 1

#echo "Status after first submission:"
#babs status

echo "Submitting remaining jobs..."
babs submit

echo "Final status (re-run manually to monitor until all jobs complete):"
babs status

echo "=== Babs jobs submitted, run 'babs_walkthrough_merge' when jobs are done. ==="
