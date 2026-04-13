#!/usr/bin/env bash
# Package src/ into dist/send-to-kindle.xpi
# Usage: scripts/build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"
DIST="$ROOT/dist"

if [[ ! -f "$SRC/manifest.json" ]]; then
  echo "error: $SRC/manifest.json not found." >&2
  exit 1
fi

mkdir -p "$DIST"
OUT="$DIST/send-to-kindle.xpi"
rm -f "$OUT"

# .xpi is just a zip. Must be zipped from INSIDE src/ so manifest.json is at root.
(cd "$SRC" && zip -r -FS "$OUT" . -x "*.DS_Store" "*.map") >/dev/null
echo "built: $OUT"
ls -lh "$OUT"
