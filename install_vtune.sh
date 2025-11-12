#!/usr/bin/env bash
#
# Intel VTune Profiler Setup Script for CloudLab Nodes
# Installs VTune, configures GCC 11, fixes kernel profiling settings,
# and rebuilds the SEP driver for system-wide performance analysis.
#
set -e

# --- Configuration ---
VTUNE_SEP_SRC="/opt/intel/oneapi/vtune/latest/sepdk/src"
DRIVER_MODULE="$VTUNE_SEP_SRC/sep5.ko"
PERF_CONF_FILE="/etc/sysctl.d/99-vtune-perf.conf"
SEP_MAJOR_NUMBER=509  # Based on observed dmesg output

echo "[INFO] Starting Intel VTune installation and setup..."

# --- 1. Repository Setup ---
mkdir -p ~/tmp && cd ~/tmp
wget -q https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
echo "deb https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update -y

# --- 2. GCC 11 Installation ---
echo "[INFO] Installing GCC 11..."
sudo apt install -y gcc-11 g++-11
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 110
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 110
sudo update-alternatives --set gcc /usr/bin/gcc-11
sudo update-alternatives --set g++ /usr/bin/g++-11
gcc --version

# --- 3. VTune Installation ---
echo "[INFO] Installing Intel VTune Profiler..."
sudo apt install -y intel-oneapi-vtune

# --- 4. Kernel Profiling Configuration ---
echo "[INFO] Configuring kernel parameters for system-wide profiling..."
echo -e "kernel.perf_event_paranoid = 0\nkernel.kptr_restrict = 0" | sudo tee "$PERF_CONF_FILE" > /dev/null
sudo sysctl -p "$PERF_CONF_FILE"
sudo apt install -y linux-headers-$(uname -r) linux-modules-extra-$(uname -r)

# --- 5. VTune Environment Setup ---
echo "[INFO] Adding VTune environment to ~/.bashrc..."
grep -qxF 'source /opt/intel/oneapi/vtune/latest/env/vars.sh' ~/.bashrc || \
echo -e '\n# Intel VTune environment\nif [ -f /opt/intel/oneapi/vtune/latest/env/vars.sh ]; then\n    source /opt/intel/oneapi/vtune/latest/env/vars.sh\nfi' >> ~/.bashrc
source ~/.bashrc

# --- 6. SEP Driver Build and Load ---
if [ -d "$VTUNE_SEP_SRC" ]; then
    echo "[INFO] Rebuilding VTune SEP driver..."
    cd "$VTUNE_SEP_SRC"
    sudo make clean || true
    sudo make

    echo "[INFO] Loading SEP driver..."
    sudo rmmod sep5 2>/dev/null || true
    sudo insmod "$DRIVER_MODULE"

    if [ ! -c /dev/sep ]; then
        sudo mknod /dev/sep c $SEP_MAJOR_NUMBER 0
    fi
    sudo chgrp users /dev/sep || true
    sudo chmod 666 /dev/sep || true

    echo "[INFO] Enabling SEP driver service..."
    sudo systemctl daemon-reload || true
    sudo systemctl stop sep5.service 2>/dev/null || true
    sudo systemctl start sep5.service 2>/dev/null || true
    sudo systemctl enable sep5.service || true
else
    echo "[WARN] SEP driver source not found; using perf-based collection only."
fi

source ~/.bashrc
echo "[INFO] VTune setup complete. You can now run profiling using:"
echo "       vtune -collect uarch-exploration -- <app command>"
