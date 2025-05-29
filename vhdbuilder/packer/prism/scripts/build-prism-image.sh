
#!/bin/bash

set -euo pipefail

# Set PROJECT_ROOT (4 directories up from this script)
PROJECT_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../../../..")"
export PROJECT_ROOT

export CONFIG_SOURCE="$PROJECT_ROOT/vhdbuilder/packer/prism/configs"

echo "Project root: $PROJECT_ROOT"

docker run --rm \
    --privileged \
    -v "$BUILD_OUT_BASE_DIR:$BUILD_OUT_BASE_DIR:z" \
    -v "$PROJECT_ROOT:/AgentBaker:z" \
    -v "/dev:/dev" \
    -v "$CONFIG_SOURCE:$CONFIG_SOURCE:z" \
    "$PRISM_IMG_REFERENCE:$PRISM_IMG_VERSION" \
    imagecustomizer \
        --build-dir "$BUILD_OUT_BASE_DIR/build" \
        --config-file "AgentBaker/vhdbuilder/packer/prism/configs/linuxguard/prism-linuxguard.yml" \
        --image-file "AgentBaker/artifacts/image.vhdx" \
        --log-level "debug" \
        --output-image-format "raw" \
        --output-image-file "$BUILD_OUT_BASE_DIR/out/linuxguard-aks.raw"