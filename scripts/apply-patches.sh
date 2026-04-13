#!/usr/bin/env bash
# Rebuild src/ from the user's local Chrome install + patches/firefox-port.patch
# Usage: scripts/apply-patches.sh
#
# Requires the upstream extension to be installed in Chrome.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_ID="cgdjpilhipecahhcilnafpblkieebhea"   # Amazon Send to Kindle
PATCH="$ROOT/patches/firefox-port.patch"
SRC_OUT="$ROOT/src"
UNPACKED="$ROOT/original/unpacked"

# Locate the user's Chrome extension install
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
if [[ ! -d "$CHROME_DIR" ]]; then
  echo "error: Chrome profile not found at $CHROME_DIR" >&2
  echo "Install the 'Send to Kindle' extension in Chrome first." >&2
  exit 1
fi

# Search all profiles for the extension
EXT_VERSION_DIR=""
while IFS= read -r -d '' candidate; do
  if [[ -d "$candidate" ]]; then
    # Take the most recent version folder
    latest="$(ls "$candidate" 2>/dev/null | sort -V | tail -n1 || true)"
    if [[ -n "$latest" && -f "$candidate/$latest/manifest.json" ]]; then
      EXT_VERSION_DIR="$candidate/$latest"
      break
    fi
  fi
done < <(find "$CHROME_DIR" -maxdepth 4 -type d -name "$EXT_ID" -print0 2>/dev/null)

if [[ -z "$EXT_VERSION_DIR" ]]; then
  echo "error: upstream extension $EXT_ID not found in any Chrome profile." >&2
  echo "Install 'Send to Kindle' from the Chrome Web Store, then re-run." >&2
  exit 1
fi

echo "found upstream: $EXT_VERSION_DIR"

# Stage the upstream source
rm -rf "$UNPACKED" "$SRC_OUT"
mkdir -p "$UNPACKED" "$SRC_OUT"
cp -R "$EXT_VERSION_DIR"/. "$UNPACKED"/
rm -rf "$UNPACKED/_metadata"
cp -R "$UNPACKED"/. "$SRC_OUT"/

# Apply the Firefox port patch
if [[ ! -f "$PATCH" ]]; then
  echo "error: $PATCH not found." >&2
  exit 1
fi

# The patch was generated via `diff -ruN original/unpacked/ src/`, so the "new"
# side path is `src/<file>`. With -p1 the `src/` prefix is stripped, then we
# apply inside $SRC_OUT.
cd "$ROOT"
patch -p1 --directory="$SRC_OUT" -i "$PATCH" --forward --quiet || {
    echo "error: patch application failed." >&2
    echo "The upstream extension may have changed. Re-derive the patch:" >&2
    echo "  diff -ruN original/unpacked/ src/ > patches/firefox-port.patch" >&2
    exit 1
}

# Overlay our independent replacement icons (non-Amazon artwork) over the
# upstream icon/ directory. These icons are our own work, shipped in the repo
# directly rather than encoded as binary hunks in the patch.
if [[ -d "$ROOT/icons" ]]; then
  cp "$ROOT"/icons/*.png "$SRC_OUT/icon/"
  echo "overlaid replacement icons from $ROOT/icons/"
fi

echo "built src/ from upstream $EXT_VERSION_DIR + patches/firefox-port.patch"
echo "next: scripts/build.sh to package dist/send-to-kindle.xpi"
