#!/bin/bash
# BABS walkthrough script — merge results for a BIDS study project
# Usage: bash babs_walkthrough_merge_bids_layout.sh <path>
#
# <path> is either:
#   - a full path to the BABS project directory, or
#   - a relative path placed under BABS_BIDS_STUDY_DIR/derivatives/

set -eux
PS4='> '

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>" >&2
    exit 1
fi

# Load custom local settings
if [ -e .env ]; then
    source .env
    echo "Configuration after loading:"
    set | grep -e BABS_
fi

ARG="$1"
case "${ARG}" in
    /*)
        BABS_PROJECT="${ARG}"
        ;;
    *)
        : "${BABS_BIDS_STUDY_DIR:?Error: BABS_BIDS_STUDY_DIR is not set}"
        BABS_PROJECT="${BABS_BIDS_STUDY_DIR}/derivatives/${ARG}"
        ;;
esac

echo ""
echo "=== Merge results: ${BABS_PROJECT} ==="

cd "${BABS_PROJECT}"

echo "Merging BABS results..."
babs merge

ANALYSIS_PATH=$(grep 'analysis_path' .babs/babs_init_config.yaml | sed 's/.*analysis_path:[[:space:]]*//' | tr -d '"' )
ANALYSIS_PATH="${ANALYSIS_PATH:-analysis}"

echo "Going to the analuysis directoy: ${ANALYSIS_PATH}, to update the results and unzip tehrm"
echo "Updating output dataset..."
cd "${ANALYSIS_PATH}"
datalad update --how ff-only --sibling output

echo "Extracting zip files..."
datalad run \
    -m "Extracting all .zip files" \
    --input '*.zip' \
    -- bash -c 'for f in *.zip; do datalad add-archive-content -D --allow-dirty --no-commit --strip-leading-dirs --leading-dirs-depth 1 --annex-options="--no-check-gitignore" "$f"; done'

echo "=== Merge complete: ${BABS_PROJECT} ==="
