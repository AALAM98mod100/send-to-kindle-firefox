# Send to Kindle — Unofficial Firefox Port

An unofficial Firefox port of Amazon's "Send to Kindle" Chrome extension for **personal use**.

This repo contains **only the modifications** needed to run the upstream extension in Firefox — not the extension itself. To build the `.xpi`, you must have Amazon's "Send to Kindle" extension installed in Google Chrome on the same machine; the build script reads the upstream source from your Chrome profile and applies the Firefox patch on top.

Amazon's code is **not redistributed** through this repository. The upstream extension is © Amazon.com, Inc. This project is not affiliated with, endorsed by, or supported by Amazon. "Kindle" and "Send to Kindle" are trademarks of Amazon.com, Inc.

## Project Layout

```
send-to-kindle-firefox/
├── patches/
│   └── firefox-port.patch   # The Firefox port (the only code tracked in git)
├── scripts/
│   ├── apply-patches.sh     # Stage upstream from Chrome + apply patch -> src/
│   ├── unpack.sh            # Alternative: unpack a .crx file into original/unpacked/
│   └── build.sh             # Package src/ -> dist/send-to-kindle.xpi
├── PORTING_NOTES.md         # What was changed and why
├── README.md
└── .gitignore               # Excludes src/, original/, dist/
```

Directories that are **not tracked** and are built on demand:

- `original/unpacked/` — a copy of the upstream extension, pulled from your Chrome install
- `src/` — the patched, Firefox-compatible source
- `dist/` — built `.xpi` files

## Prerequisites

1. Install Amazon's **Send to Kindle** extension in Google Chrome from the [Chrome Web Store](https://chromewebstore.google.com/detail/send-to-kindle/cgdjpilhipecahhcilnafpblkieebhea). The build script reads the source from:
   ```
   ~/Library/Application Support/Google/Chrome/<Profile>/Extensions/cgdjpilhipecahhcilnafpblkieebhea/<version>/
   ```
2. macOS. (Paths above are Mac-specific; Linux/Windows would need the script adapted.)

## Build

```bash
# 1. Reconstruct src/ from your local Chrome install + the Firefox patch
./scripts/apply-patches.sh

# 2. Package src/ into dist/send-to-kindle.xpi
./scripts/build.sh
```

## Install in Firefox

### Temporary (dev / testing)

1. Open `about:debugging#/runtime/this-firefox`
2. Click **Load Temporary Add-on**
3. Select `src/manifest.json`
4. Log into `amazon.com` in Firefox (separate cookie jar from Chrome)

Temporary add-ons vanish on Firefox restart.

### Permanent (signed install)

Release Firefox refuses unsigned add-ons. To install permanently:

1. Create an account at [addons.mozilla.org](https://addons.mozilla.org/developers/)
2. Submit `dist/send-to-kindle.xpi` at [addons.mozilla.org/developers/addon/submit/distribution](https://addons.mozilla.org/developers/addon/submit/distribution)
3. Choose **"On your own"** (unlisted — not publicly searchable)
4. Mozilla signs it in minutes; download the signed `.xpi` from your dashboard
5. Install by dragging the signed `.xpi` into Firefox, or `about:addons` → gear → **Install Add-on From File**

Alternative: use Firefox Developer Edition / ESR / Nightly and set `xpinstall.signatures.required = false` in `about:config`.

## Updating the Patch

If the upstream extension updates and you want to re-derive the patch against the new version:

```bash
./scripts/apply-patches.sh                              # rebuild src/ from new upstream
# make further edits to src/
mkdir -p /tmp/s2k_p && rm -rf /tmp/s2k_p/*
cp -R original/unpacked/. /tmp/s2k_p/a/
cp -R src/. /tmp/s2k_p/b/
(cd /tmp/s2k_p && diff -ruN a b) > patches/firefox-port.patch
rm -rf /tmp/s2k_p
```

## What the Patch Does

See [`PORTING_NOTES.md`](PORTING_NOTES.md) for details. Summary:

- Adapts `manifest.json` for Firefox (adds `browser_specific_settings.gecko`, swaps `background.service_worker` → `background.scripts`, changes `incognito: split` → `spanning`, removes Chrome-only keys)
- Replaces hardcoded `chrome-extension://${id}` URLs with `chrome.runtime.getURL()` so they produce `moz-extension://...` URLs in Firefox
- Widens the "don't inject into privileged schemes" checks to cover `moz-extension://` and `about:`
- Renames the extension to **"Send to Kindle (Unofficial Firefox Port)"** across all 29 locales
