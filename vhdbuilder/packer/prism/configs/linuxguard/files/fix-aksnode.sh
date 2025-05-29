#!/bin/bash

BASE_DIR="/var/lib/waagent"

FILE_PATTERN="Microsoft.AKS.Compute.AKS.Linux.AKSNode-*/entrypoint.py"

while true; do
  FILES=$(find "$BASE_DIR" -path "$BASE_DIR/$FILE_PATTERN" -type f 2>/dev/null)

  if [[ -n "$FILES" ]]; then
    echo "$FILES"

    while IFS= read -r FILE; do
      echo "Running sed: $FILE"
      sed -i 's|"node-problem-detector", "node-exporter", "ig"||' "$FILE"
    done <<< "$FILES"
  fi

  sleep 0.5
done
