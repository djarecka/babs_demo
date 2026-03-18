#!/usr/bin/env bash                                                                                          

set -eux
PS4='> '

# Accept dataset name and input path as arguments
BABS_PROJECT="$1"  # Accept site name
BASENAME=$(basename "$(dirname "$BABS_PROJECT")")


if [ -e .env ]; then
    source .env
    echo "Configuration of output dir after loading env"
    set | grep -e BABS_OUTPUT_DIR
fi

TARGET_DIR="${BABS_OUTPUT_DIR}/${BASENAME}"


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
ls -l

echo ""
echo "=== Walkthrough complete ==="
echo "To inspect a specific subject's output, run:"
echo "  datalad get <subject_zip_file>"
echo "  unzip -l <subject_zip_file>"
