#!/bin/bash
# Regenerate files/repart.d/* based on the disks section of aks-config.yaml
# Requires: yq (https://github.com/mikefarah/yq)
# Usage: generate-repartd.sh <CONFIG_FILE> <REPART_DIR>

set -euo pipefail

# Function to show usage
usage() {
    echo "Usage: $0 <CONFIG_FILE> <REPART_DIR>"
    echo "  CONFIG_FILE: Path to aks-config.yaml file"
    echo "  REPART_DIR:  Directory where repart.d config files will be generated"
    exit 1
}

# Check arguments
if [[ $# -ne 2 ]]; then
    echo "Error: Invalid number of arguments"
    usage
fi

CONFIG="$1"
REPART_DIR="$2"

# Validate inputs
if [[ ! -f "$CONFIG" ]]; then
    echo "Error: Config file '$CONFIG' not found"
    exit 1
fi

mkdir -p "$REPART_DIR"
rm -f "$REPART_DIR"/*.conf

emit_partition() {
    local num="$1" part="$2" type="$3" label="$4" size="$5"
    # Set Type for root and root-hash partitions
    if [[ "$part" =~ ^root(-(a|b))?$ ]]; then
        type_out="root-x86-64"
    elif [[ "$part" =~ ^root-hash(-(a|b))?$ ]]; then
        type_out="root-x86-64-verity"
    else
        type_out="$type"
    fi
    if [[ "$part" =~ ^var(-(a|b))?$ ]]; then
        cat > "$REPART_DIR/$(printf '%02d' $num)-${part}.conf" <<EOF
[Partition]
Type=$type_out
Label=$label
SizeMinBytes=10G
Weight=1000
EOF
    else
        cat > "$REPART_DIR/$(printf '%02d' $num)-${part}.conf" <<EOF
[Partition]
Type=$type_out
Label=$label
SizeMinBytes=$size
SizeMaxBytes=$size
EOF
    fi
}

# Generate all A partitions and collect B info
num=10
declare -a bparts
for part in $(yq -r '.storage.disks[0].partitions[].id' "$CONFIG"); do
    type=$(yq -r ".storage.disks[0].partitions[] | select(.id == \"$part\") | .type" "$CONFIG")
    label=$(yq -r ".storage.disks[0].partitions[] | select(.id == \"$part\") | .label" "$CONFIG")
    size=$(yq -r ".storage.disks[0].partitions[] | select(.id == \"$part\") | .size" "$CONFIG")
    emit_partition $num $part $type $label $size
    if [[ "$part" =~ ^(boot|root|root-hash|var)-a$ ]]; then
        bpart="${part/-a/-b}"
        blabel="${label/-a/-b}"
        bparts+=("$bpart|$type|$blabel|$size")
    fi
    num=$((num+1))
done

# Generate all B partitions
for b in "${bparts[@]}"; do
    IFS='|' read -r bpart type blabel size <<< "$b"
    emit_partition $num $bpart $type $blabel $size
    num=$((num+1))
done

echo "Repart.d configs generated successfully in $REPART_DIR"
echo "Generated $(find "$REPART_DIR" -name "*.conf" | wc -l) partition configuration files"