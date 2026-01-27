#!/bin/bash
set -e

# Setup script for Allocator Test Suite dependencies
# Usage: ./setup_allocators.sh

BASE_DIR=$(pwd)
ALLOC_DIR="$BASE_DIR/allocators"

echo "[*] Checking for build dependencies..."
for cmd in git cmake autoconf automake make cc; do
    if ! command -v $cmd &> /dev/null; then
        echo "[!] Error: $cmd is not installed."
        exit 1
    fi
done

echo "[*] Setting up dependencies in $ALLOC_DIR..."
mkdir -p "$ALLOC_DIR"


MIMALLOC_DIR="$ALLOC_DIR/mimalloc/mimalloc_src"
if [ ! -d "$MIMALLOC_DIR" ]; then
    echo "[*] Cloning mimalloc..."
    git clone https://github.com/microsoft/mimalloc "$MIMALLOC_DIR"
else
    echo "[*] mimalloc already cloned."
fi

# Build Mimalloc (Secure/Debug)
echo "[*] Building mimalloc (secure)..."
mkdir -p "$BASE_DIR/build_secure"
cd "$BASE_DIR/build_secure"
cmake "$MIMALLOC_DIR" -DMI_SECURE=ON -DMI_BUILD_SHARED=OFF -DMI_BUILD_TESTS=OFF
make -j$(nproc)
cd "$BASE_DIR"

JEMALLOC_DIR="$ALLOC_DIR/jemalloc/jemalloc_src"
mkdir -p "$ALLOC_DIR/jemalloc"

if [ ! -d "$JEMALLOC_DIR" ]; then
    echo "[*] Cloning jemalloc..."
    git clone https://github.com/jemalloc/jemalloc "$JEMALLOC_DIR"
else
    echo "[*] jemalloc already cloned."
fi

# Build Jemalloc (Static, Prefixed)
echo "[*] Building jemalloc..."
cd "$JEMALLOC_DIR"
if [ ! -f "configure" ]; then
    ./autogen.sh
fi

if [ ! -f "Makefile" ]; then
    # Prefix with je_ to avoid conflicts
    ./configure --with-jemalloc-prefix=je_ --disable-shared --enable-static
fi

make -j$(nproc)
cd "$BASE_DIR"

echo "[+] Setup complete! Libraries built."
echo "    - Mimalloc: build_secure/libmimalloc-secure.a"
echo "    - Jemalloc: allocators/jemalloc/jemalloc_src/lib/libjemalloc.a"
