#!/usr/bin/env bash
#
# SNAP Dataset Downloader and Preprocessor
# Downloads selected SNAP graphs, decompresses, and cleans them into .el (edge list) format.
#
set -euo pipefail

# --- Configuration ---
BASE_URL="https://snap.stanford.edu/data"
DOWNLOAD_DIR="$HOME/snap_datasets"
EDGE_LIST_DIR="${DOWNLOAD_DIR}/el"

# --- Setup ---
mkdir -p "${EDGE_LIST_DIR}"
cd "${DOWNLOAD_DIR}" || { echo "[ERROR] Cannot access ${DOWNLOAD_DIR}"; exit 1; }

echo "[INFO] Downloading and preparing SNAP datasets..."

# Dataset list: (SNAP_component base_filename)
datasets=(
    "egonets-Facebook facebook_combined"
    "p2p-Gnutella31 p2p-Gnutella31"
    "web-Stanford web-Stanford"
    "roadNet-PA roadNet-PA"
)

# --- Download, decompress, and clean ---
for entry in "${datasets[@]}"; do
    read -r SNAP_COMPONENT BASE_FILENAME <<< "${entry}"

    COMPRESSED_FILE="${BASE_FILENAME}.txt.gz"
    RAW_FILE="${BASE_FILENAME}.txt"
    CLEAN_FILE="${EDGE_LIST_DIR}/${BASE_FILENAME}.el"
    DOWNLOAD_URL="${BASE_URL}/${COMPRESSED_FILE}"

    echo "[INFO] Processing ${BASE_FILENAME}..."

    # Download if not already present
    if [[ ! -f "${RAW_FILE}" && ! -f "${COMPRESSED_FILE}" ]]; then
        echo "  - Downloading ${COMPRESSED_FILE}"
        wget -q --show-progress -c "${DOWNLOAD_URL}" || {
            echo "[WARN] Failed to download ${COMPRESSED_FILE}. Skipping."
            continue
        }
    fi

    # Decompress if needed
    if [[ -f "${COMPRESSED_FILE}" ]]; then
        echo "  - Decompressing..."
        gunzip -f "${COMPRESSED_FILE}" || {
            echo "[WARN] Failed to decompress ${COMPRESSED_FILE}. Skipping."
            continue
        }
    fi

    # Clean to .el format
    echo "  - Cleaning and converting to edge list..."
    grep -v "^#" "${RAW_FILE}" > "${CLEAN_FILE}" || {
        echo "[WARN] Failed to clean ${RAW_FILE}."
        continue
    }

    echo "  - Saved cleaned file: ${CLEAN_FILE}"
done

echo "[INFO] All datasets processed successfully."
echo "[INFO] Clean edge list files are available in: ${EDGE_LIST_DIR}"
