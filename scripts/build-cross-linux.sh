#!/usr/bin/env bash
# Build the plugin inside cross's Ubuntu 20.04 (glibc 2.31) container
# and assemble the CLAP / VST3 bundles by hand. Use this instead of
# `cargo xtask bundle` when targeting older glibc — `cross xtask` does
# not reliably reroute the nested build into the container.
set -euo pipefail

TARGET=${TARGET:-x86_64-unknown-linux-gnu}
PROFILE=${PROFILE:-release}
PROFILE_DIR=$([ "$PROFILE" = "dev" ] && echo "debug" || echo "$PROFILE")

cd "$(dirname "$0")/.."

echo "==> Building gain_knob via cross ($TARGET, $PROFILE)"
cross build --"$PROFILE" -p gain_knob --target "$TARGET"

ARTIFACT="target/$TARGET/$PROFILE_DIR/libgain_knob.so"
if [ ! -f "$ARTIFACT" ]; then
    echo "ERROR: expected $ARTIFACT to exist after build" >&2
    exit 1
fi

OUT="target/bundled-cross"
echo "==> Bundling into $OUT/"
rm -rf "$OUT/gain_knob.clap" "$OUT/gain_knob.vst3"
mkdir -p "$OUT"

# CLAP: a single shared object renamed.
cp "$ARTIFACT" "$OUT/gain_knob.clap"

# VST3 Linux: directory bundle with Contents/<arch>-linux/<name>.so
ARCH_DIR="x86_64-linux"
case "$TARGET" in
    aarch64-*) ARCH_DIR="aarch64-linux" ;;
esac
mkdir -p "$OUT/gain_knob.vst3/Contents/$ARCH_DIR"
cp "$ARTIFACT" "$OUT/gain_knob.vst3/Contents/$ARCH_DIR/gain_knob.so"

echo "Done."
echo "  CLAP: $OUT/gain_knob.clap"
echo "  VST3: $OUT/gain_knob.vst3"
echo
echo "Verify the glibc version with:"
echo "  objdump -T '$ARTIFACT' | grep GLIBC_ | awk '{print \$5}' | sort -u"
