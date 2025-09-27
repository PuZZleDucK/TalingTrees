#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <path/to/image> [output_dir]" >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "This script must be run inside a git repository" >&2
  exit 1
fi

if ! git show HEAD:"$1" >/dev/null 2>&1; then
  echo "No version of $1 found in HEAD" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Current working tree does not contain $1" >&2
  exit 1
fi

if command -v compare >/dev/null 2>&1; then
  COMPARE=(compare)
elif command -v magick >/dev/null 2>&1; then
  COMPARE=(magick compare)
else
  echo "ImageMagick 'compare' command not found. Install ImageMagick to use this script." >&2
  exit 1
fi

IMAGE_PATH="$1"
OUT_DIR="${2:-screenshots/diffs}"
BASENAME="$(basename "$IMAGE_PATH")"
mkdir -p "$OUT_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git show HEAD:"$IMAGE_PATH" > "$tmpdir/original.png"
cp "$IMAGE_PATH" "$tmpdir/current.png"

set +e
${COMPARE[@]} -compose src -highlight-color red -lowlight-color black \
  "$tmpdir/original.png" "$tmpdir/current.png" "$tmpdir/diff.png"
compare_status=$?
set -e

if [ $compare_status -gt 1 ]; then
  echo "Image comparison failed with status $compare_status" >&2
  exit $compare_status
fi

if command -v montage >/dev/null 2>&1; then
  montage -label "Original" "$tmpdir/original.png" \
          -label "Current" "$tmpdir/current.png" \
          -label "Diff" "$tmpdir/diff.png" \
          -tile 3x1 -geometry +10+10 "$OUT_DIR/${BASENAME%.png}-comparison.png"
  echo "Saved diff montage to $OUT_DIR/${BASENAME%.png}-comparison.png"
else
  cp "$tmpdir/diff.png" "$OUT_DIR/${BASENAME%.png}-diff.png"
  echo "Saved diff image to $OUT_DIR/${BASENAME%.png}-diff.png"
fi
