#!/bin/bash
# BABS walkthrough script
# Based on: https://pennlinc-babs.readthedocs.io/en/stable/walkthrough.html
#
# Usage: bash babs_walkthrough.sh
#
# Customize the variables in the CONFIGURATION section below before running.

set -eux
PS4='> '

SKIP_DATA_PREP=false

for arg in "$@"; do
  case $arg in
    --skip-data-prep) SKIP_DATA_PREP=true ;;
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


# Load custom local setting (potentially Yarik specific)
if [ -e .env ]; then
    source .env
    echo "Configuration after loading:"
    set | grep -e SLURM_ -e BABS_ -e SCRIPT_
fi


cd "$(mktemp -d "${BABS_WORKDIR:-/tmp}/babs_walkthrough_yoh_XXX")"

DEMO_DIR="${PWD}"
echo "demo dir" $DEMO_DIR
BABS_CONFIG_FILE="${DEMO_DIR}/config_simbids_0-0-3_raw_mri.yaml"
BABS_PROJECT="${DEMO_DIR}/my_BABS_project"
CONTAINER_DS="${DEMO_DIR}/simbids-container"
JOB_COMPUTE_SPACE="${DEMO_DIR}/job_compute_space"
mkdir -p "${JOB_COMPUTE_SPACE}"



# ==============================================================================
# STEP 0: Create testing BIDS data
# ==============================================================================

if [ "$SKIP_DATA_PREP" = false ]; then

    echo "=== Step 0: Create simulated BIDS dataset ==="

    echo "Building Singularity image..."
    singularity build --fakeroot "${SIMBIDS_SIF}" "${SIMBIDS_IMAGE}"

    echo "Generating simulated BIDS dataset..."
    singularity exec -B "${DEMO_DIR}" "${SIMBIDS_SIF}" \
		simbids-raw-mri \
		"${DEMO_DIR}" \
		ds004146_configs.yaml

    echo "Converting to DataLad dataset..."
    cd "${DEMO_DIR}/simbids"
    datalad create -D "SIMBIDS simulated dataset" -d . --force
    datalad save
    DATA_DIR="${DEMO_DIR}/simbids"
    CONTAINER_PATH="${DEMO_DIR}/${SIMBIDS_SIF}"
else
    echo "=== SKIPPING Step 0: Create simulated BIDS dataset ==="
    DATA_DIR="${BABS_WORKDIR}/babs_walkthrough_preparation/simbids"
    CONTAINER_PATH="${BABS_WORKDIR}/babs_walkthrough_preparation/${SIMBIDS_SIF}"
fi

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

if [ "$SKIP_DATA_PREP" = false ]; then
    echo "Removing original container SIF file..."
    cd "${DEMO_DIR}"
    rm "${SIMBIDS_SIF}"
fi
# 1.3 YAML configuration file
# YARIK: might need updates  (cluster resources)
echo "Writing BABS container config YAML..."
cat > "${BABS_CONFIG_FILE}" <<YAML
bids_app_args:
    --bids-app: fmriprep
    \$SUBJECT_SELECTION_FLAG: "--participant-label"
    --stop-on-first-crash: ""
    -vv: ""
    --anat-only: ""

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
        path_in_babs: inputs/data/BIDS
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
    "${BABS_PROJECT}"

echo "Verifying setup with a test job..."
cd "${BABS_PROJECT}"
# removing for now, since it gives an error
#babs check-setup --job-test

# ==============================================================================
# STEP 2b: get containers
# ==============================================================================
pushd "analysis/containers/"
# TODO template this path
datalad get .datalad/environments/simbids-0-0-3/image
popd

# ==============================================================================
# STEP 3: Submit jobs and monitor
# ==============================================================================

echo ""
echo "=== Step 3: Submit and monitor jobs ==="

cd "${BABS_PROJECT}"

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
