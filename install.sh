#!/usr/bin/env bash
# nginx-lab install script

set -euo pipefail

echo ""
echo "  [nginx-lab] Installing..."
echo ""
echo "  This plugin demonstrates how to install and configure Nginx"
echo "  as a web server inside a QEMU virtual machine."
echo ""
echo "  What you will learn:"
echo "    - How to provision packages via cloud-init"
echo "    - How to configure Nginx inside a VM"
echo "    - How to access a web server running in a VM via port forwarding"
echo "    - How to test HTTP responses with curl"
echo ""

# Create lab working directory
mkdir -p lab

# Check for required tools
echo "  Checking dependencies..."
local_ok=true
for cmd in qemu-system-x86_64 qemu-img genisoimage curl; do
    if command -v "$cmd" &>/dev/null; then
        echo "    [OK] $cmd"
    else
        echo "    [!!] $cmd — not found (install before running)"
        local_ok=false
    fi
done

if [[ "$local_ok" == true ]]; then
    echo ""
    echo "  All dependencies are available."
else
    echo ""
    echo "  Some dependencies are missing. Install them with:"
    echo "    sudo apt install qemu-kvm qemu-utils genisoimage curl"
fi

echo ""
echo "  [nginx-lab] Installation complete."
echo "  Run with: qlab run nginx-lab"
