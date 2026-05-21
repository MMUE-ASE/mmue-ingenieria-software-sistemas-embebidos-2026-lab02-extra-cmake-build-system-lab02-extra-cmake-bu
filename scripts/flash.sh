#!/usr/bin/env bash
# flash.sh — Flash firmware onto the NUCLEO-F412ZG via OpenOCD + ST-LINK.
#
# Usage (called automatically by "cmake --build build --target flash"):
#   bash scripts/flash.sh <path-to-elf>
#
# The ELF path is passed by CMakeLists.txt via $<TARGET_FILE:lab2>.
# Default fallback lets you also call this script manually.
set -euo pipefail

ELF="${1:-build/lab2.elf}"

if [[ ! -f "$ELF" ]]; then
    echo "ERROR: $ELF not found — run 'cmake --build build' first."
    exit 1
fi

if ! command -v openocd &>/dev/null; then
    echo "ERROR: openocd not found in PATH."
    echo "       Linux/WSL: sudo apt install openocd"
    echo "       Windows:   download from gnutoolchains.com/arm-eabi/openocd/"
    exit 1
fi

echo "Flashing ${ELF} via ST-LINK (OpenOCD)..."
openocd \
    -f interface/stlink.cfg \
    -c "transport select swd" \
    -f target/stm32f4x.cfg \
    -c "program ${ELF} verify reset exit"
echo "Done."
