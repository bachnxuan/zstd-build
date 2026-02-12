#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)"

source "$WORKSPACE/utils.sh"

# Build configuration
SOURCE="$WORKSPACE/zstd"
JOBS="${JOBS:-$(nproc --all)}"
OUT="$WORKSPACE/out"
TARGET="zstd-decompress"

# Compiler configuration
CC="zig cc -target aarch64-linux-musl"
CFLAGS="-O2 -DNDEBUG -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables"
CPPFLAGS="-DZSTD_STRIP_ERROR_STRINGS=1"
LDFLAGS="-static -Wl,--gc-sections,--strip-all"

prepare() {
    # Prepare directory
    info "Preparing directories..."
    DIRS=(
        "$SOURCE" "$OUT"
    )
    for dir in "${DIRS[@]}"; do
        reset_dir "$dir"
    done

    # Clone source
    info "Cloning zstd..."
    local tag="$(latest_tag facebook/zstd)"
    git_clone "facebook/zstd@$tag" "$SOURCE" &>/dev/null
}

build() {
    info "Building zstd..."
    make -j"$JOBS" -C "$SOURCE/programs" \
        CC="$CC" CFLAGS="$CFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" \
        "$TARGET"
}

finalize() {
    cp -f "$SOURCE/programs/$TARGET" "$OUT/zstd"
    info "Complete build at: $OUT/zstd"
}

main() {
    prepare
    build
    finalize
}

main "$@"
