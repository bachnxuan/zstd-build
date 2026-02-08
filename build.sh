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

MAKE_OPTS=(
    ZSTD_NOBENCH=1        # Drops benchmark code
    ZSTD_NODICT=1         # Drops dict training
    ZSTD_LEGACY_SUPPORT=0 # Drops legacy decode
    HAVE_THREAD=0         # No threading support
    HAVE_ZLIB=0           # No gzip support
    HAVE_LZMA=0           # No xz/lzma support
    HAVE_LZ4=0            # No lz4 support
)

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
    git_clone "facebook/zstd@$tag" "$SOURCE" &> /dev/null
}

build() {
    info "Building zstd..."
    make -j"$JOBS" -C "$SOURCE/programs" \
        CC="$CC" CFLAGS="$CFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" \
        "${MAKE_OPTS[@]}" "$TARGET"
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
