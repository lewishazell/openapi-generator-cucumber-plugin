#!/bin/bash

# Script to update snapshots by copying .received.json to .verified.json
# Usage: ./update_snapshots.sh

SNAPSHOTS_DIR="snapshots"

if [ ! -d "$SNAPSHOTS_DIR" ]; then
    echo "Error: Snapshots directory not found: $SNAPSHOTS_DIR"
    exit 1
fi

for received_file in "$SNAPSHOTS_DIR"/*/*.received.json; do
    if [ -f "$received_file" ]; then
        verified_file="${received_file/.received.json/.verified.json}"
        cp "$received_file" "$verified_file"
        echo "Updated: $verified_file"
    fi
done

for received_file in "$SNAPSHOTS_DIR"/*.received.json; do
    if [ -f "$received_file" ]; then
        verified_file="${received_file/.received.json/.verified.json}"
        cp "$received_file" "$verified_file"
        echo "Updated: $verified_file"
    fi
done

echo "All snapshots updated."