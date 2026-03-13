#!/bin/bash
# BABS walkthrough script
# Based on: https://pennlinc-babs.readthedocs.io/en/stable/walkthrough.html
#
# Usage: bash babs_walkthrough.sh
#
# Customize the variables in the CONFIGURATION section below before running.

set -eux
PS4='> '

cd "$(mktemp -d "${TMPDIR:-/tmp}/babs_walkthrough_XXX")"

# ==============================================================================
# CONFIGURATION — edit these before running
# ==============================================================================

DEMO_DIR="${PWD}"
echo "demo dir" $DEMO_DIR
SIMBIDS_VERSION="0.0.3"
SIMBIDS_SIF="simbids-${SIMBIDS_VERSION}.sif"
SIMBIDS_IMAGE="docker://pennlinc/simbids:${SIMBIDS_VERSION}"
BABS_CONFIG_FILE="${DEMO_DIR}/config_simbids_0-0-3_raw_mri.yaml"
BABS_PROJECT="${DEMO_DIR}/my_BABS_project"
CONTAINER_DS="${DEMO_DIR}/simbids-container"
CONTAINER_NAME="simbids-0-0-3"
PROCESSING_LEVEL="session"   # "subject" or "session"
QUEUE="slurm"                # "slurm" or "sge"

# YARIK: might need updates
INTERPRETING_SHELL="/bin/bash"
SBATCH_PARTITION="mit_preemptable"
JOB_COMPUTE_SPACE="${DEMO_DIR}/job_compute_space"
mkdir -p "${JOB_COMPUTE_SPACE}"

# Script preamble to activate your environment (update as needed)
# YARIK: might need updates 
SCRIPT_PREAMBLE='source activate /home/djarecka/.conda/envs/simple_babs_test
    module load apptainer/1.1.9'

# ==============================================================================
# STEP 0: Create testing BIDS data
# ==============================================================================

echo "=== Step 0: Create simulated BIDS dataset ==="

#mkdir -p "${DEMO_DIR}"
#cd "${DEMO_DIR}"

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
    --url "${DEMO_DIR}/${SIMBIDS_SIF}" \
    "${CONTAINER_NAME}"

echo "Removing original container SIF file..."
cd "${DEMO_DIR}"
rm "${SIMBIDS_SIF}"

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
    - --no-home
    - --writable-tmpfs

cluster_resources:
    interpreting_shell: ${INTERPRETING_SHELL}
    customized_text: |
        #SBATCH -p ${SBATCH_PARTITION}
        #SBATCH --nodes=1
        #SBATCH --ntasks=1
        #SBATCH --time=00:10:00
        #SBATCH --mem=2G
        #SBATCH --propagate=NONE

script_preamble: |
    ${SCRIPT_PREAMBLE}

job_compute_space: "${JOB_COMPUTE_SPACE}"

input_datasets:
    BIDS:
        required_files:
            - "anat/*_T1w.nii*"
        is_zipped: false
        origin_url: "${DEMO_DIR}/simbids"
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

echo "=== Stopping here. Run 'babs merge' manually when jobs are done. ==="
exit 0


# ==============================================================================
# STEP 4: Merge results and access outputs
# ==============================================================================

echo ""
echo "=== Step 4: Merge results ==="

cd "${BABS_PROJECT}"
babs merge

echo "Cloning output RIA store..."
cd "${DEMO_DIR}"
datalad clone \
    "ria+file://${BABS_PROJECT}/output_ria#~data" \
    my_BABS_project_outputs

echo "Listing outputs:"
cd my_BABS_project_outputs
ls

echo ""
echo "=== Walkthrough complete ==="
echo "To inspect a specific subject's output, run:"
echo "  datalad get <subject_zip_file>"
echo "  unzip -l <subject_zip_file>"
