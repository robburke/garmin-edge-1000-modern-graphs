#!/usr/bin/env bash
# Build all three Varia-Safe graph fields (Power, Cadence, HR).
# Requires: Connect IQ SDK on PATH (monkeyc), a developer_key in repo root.
set -euo pipefail
DEVICE="${1:-edge_1000}"   # NOTE: the SDK device id for the Edge 1000 is edge_1000 (underscore)
if [ ! -f developer_key ]; then
  echo "developer_key not found. Generate one (see README) before building." >&2
  exit 1
fi
mkdir -p bin
for f in power cadence hr; do
  monkeyc -d "$DEVICE" -f "$f.jungle" -o "bin/VariaSafe-$f.prg" -y developer_key
  echo "built bin/VariaSafe-$f.prg ($DEVICE)"
done
