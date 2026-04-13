#!/usr/bin/env bash
# Unpack a Chrome .crx file into original/unpacked/
# Usage: scripts/unpack.sh [path/to/file.crx]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRX="${1:-}"

if [[ -z "$CRX" ]]; then
  CRX="$(ls "$ROOT"/original/*.crx 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$CRX" || ! -f "$CRX" ]]; then
  echo "error: no .crx file found. Place one in original/ or pass a path." >&2
  exit 1
fi

OUT="$ROOT/original/unpacked"
rm -rf "$OUT"
mkdir -p "$OUT"

# A .crx file is a ZIP with a prefix header. Strip the header, then unzip.
# CRX3 format: magic(4) "Cr24" + version(4) + header_length(4) + header + zip
python3 - "$CRX" "$OUT" <<'PY'
import struct, sys, zipfile, io, os
crx_path, out_dir = sys.argv[1], sys.argv[2]
with open(crx_path, "rb") as f:
    data = f.read()
magic = data[:4]
if magic != b"Cr24":
    # Assume it's already a zip
    zip_bytes = data
else:
    version = struct.unpack("<I", data[4:8])[0]
    if version == 2:
        pub_len = struct.unpack("<I", data[8:12])[0]
        sig_len = struct.unpack("<I", data[12:16])[0]
        zip_start = 16 + pub_len + sig_len
    elif version == 3:
        header_len = struct.unpack("<I", data[8:12])[0]
        zip_start = 12 + header_len
    else:
        raise SystemExit(f"unknown CRX version: {version}")
    zip_bytes = data[zip_start:]
with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
    z.extractall(out_dir)
print(f"unpacked {crx_path} -> {out_dir}")
PY

echo "done. manifest:"
ls -la "$OUT/manifest.json" 2>/dev/null || echo "  (no manifest.json found — check $OUT)"
