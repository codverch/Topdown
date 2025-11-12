#!/usr/bin/env bash
#
# Graph Benchmark Setup Script
# Clones and builds GAPBS and CRONO benchmark suites.
# Repositories:
#   GAPBS: https://github.com/litz-lab/gapbs.git
#     Benchmarks: bc, bfs, cc, sssp, pagerank, tc
#   CRONO: https://github.com/codverch/CRONO.git
#     Benchmarks: bc, bfs, cc, cd, dfs, pagerank, sssp, triangle_counting, tsp
#
set -e

echo "[INFO] Starting benchmark setup..."

# --- Clone Repositories ---
cd "$HOME" || { echo "[ERROR] Cannot access home directory."; exit 1; }

if [ ! -d "$HOME/gapbs" ]; then
    echo "[INFO] Cloning GAPBS repository..."
    git clone https://github.com/litz-lab/gapbs.git
else
    echo "[INFO] GAPBS repository already exists. Skipping clone."
fi

if [ ! -d "$HOME/CRONO" ]; then
    echo "[INFO] Cloning CRONO repository..."
    git clone https://github.com/codverch/CRONO.git
else
    echo "[INFO] CRONO repository already exists. Skipping clone."
fi

# --- Build GAPBS ---
echo "[INFO] Building GAPBS..."
cd "$HOME/gapbs" || { echo "[ERROR] GAPBS directory not found."; exit 1; }
make clean
make -j"$(nproc)" all

# --- Build CRONO ---
echo "[INFO] Building CRONO..."
cd "$HOME/CRONO" || { echo "[ERROR] CRONO directory not found."; exit 1; }
make clean
make -j"$(nproc)" all

echo "[INFO] GAPBS and CRONO benchmarks built successfully."
