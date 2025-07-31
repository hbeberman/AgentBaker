#!/bin/bash
set -e
# avoid using set -x in this pipeline as you'll end up logging a sensitive access token down below.

source ./parts/linux/cloud-init/artifacts/cse_benchmark_functions.sh

# Find the absolute path of the directory containing this script
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG=$IMG_CUSTOMIZER_CONFIG
AGENTBAKER_DIR=`realpath $SCRIPTS_DIR/../../../../`
OUT_DIR="${AGENTBAKER_DIR}/out"

required_env_vars=(
    "AZURE_MSI_RESOURCE_STRING"
    "CAPTURED_SIG_VERSION"
)

for v in "${required_env_vars[@]}"
do
    if [ -z "${!v}" ]; then
        echo "$v was not set!"
        exit 1
    fi
done

capture_benchmark "${SCRIPT_NAME}_prepare_upload_vhd_to_blob"

echo "Uploading ${OUT_DIR}/${CONFIG}.vhd to ${CLASSIC_BLOB}/${CAPTURED_SIG_VERSION}.vhd"

echo "Setting azcopy environment variables with pool identity: $AZURE_MSI_RESOURCE_STRING"
export AZCOPY_AUTO_LOGIN_TYPE="MSI"
export AZCOPY_MSI_RESOURCE_STRING="$AZURE_MSI_RESOURCE_STRING"
export AZCOPY_CONCURRENCY_VALUE="AUTO"
azcopy copy "${OUT_DIR}/${CONFIG}.vhd" "${CLASSIC_BLOB}/${CAPTURED_SIG_VERSION}.vhd" --recursive=true || exit $?

echo "Uploaded ${OUT_DIR}/${CONFIG}.vhd to ${CLASSIC_BLOB}/${CAPTURED_SIG_VERSION}.vhd"
capture_benchmark "${SCRIPT_NAME}_upload_vhd_to_blob"

# TODO: add an acg image version publish