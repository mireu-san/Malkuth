#!/bin/bash
set -o pipefail

echo "[INFO] Starting routine schedule..."
sleep 2

# trigger failure
>&2 echo "[ERROR] Abnormality escape has been detected. Call Malkuth for validation."
exit 1
