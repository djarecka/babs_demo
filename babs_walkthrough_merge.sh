#!/usr/bin/env bash                                                                                          

set -eux
PS4='> '

# Accept dataset name and input path as arguments
BABS_PROJECT="$1"  # Accept site name

BASENAME=$(basename "$(dirname "$BABS_PROJECT")")
OUTPUT_DIR="$2"  # Accept dataset name as second argument
TARGET_DIR="${OUTPUT_DIR}/${BASENAME}"


echo ""
echo "=== Step 4: Merge results of the project:" ${BASENAME}
echo "target dir" ${TARGET_DIR}

cd "${BABS_PROJECT}"
babs merge

echo "Cloning output RIA store..."
datalad clone \
    "ria+file://${BABS_PROJECT}/output_ria#~data" \
    "$TARGET_DIR"

echo "Listing outputs:"
cd "$TARGET_DIR"
ls

echo ""
echo "=== Walkthrough complete ==="
echo "To inspect a specific subject's output, run:"
echo "  datalad get <subject_zip_file>"
echo "  unzip -l <subject_zip_file>"
