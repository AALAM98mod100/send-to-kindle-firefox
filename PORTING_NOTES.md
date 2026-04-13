# Porting Notes

Checklist of things to review/modify when porting the upstream extension to Firefox.

## manifest.json

- [ ] Add `browser_specific_settings.gecko`:
  ```json
  "browser_specific_settings": {
    "gecko": {
      "id": "send-to-kindle-port@local",
      "strict_min_version": "115.0"
    }
  }
  ```
- [ ] If MV3 with `background.service_worker`, confirm Firefox ≥ 121 or fall back to `background.scripts` / `background.page` (MV2-style, still accepted by Firefox).
- [ ] Remove any Chrome-only keys (e.g. `minimum_chrome_version`, `key`, `update_url`).
- [ ] Verify `host_permissions` covers Amazon domains used by the upload endpoint.

## APIs

- [ ] `chrome.*` calls work in Firefox but are callback-based. `browser.*` is promise-based. Either is fine; don't need to swap.
- [ ] `chrome.declarativeNetRequest` — partial support in Firefox. If used for header rewrites, consider swapping to `webRequest.onBeforeSendHeaders`.
- [ ] `chrome.scripting.executeScript` — supported.
- [ ] `chrome.storage.*` — supported.
- [ ] `chrome.identity` — partial; check if used for Amazon OAuth. May need to rely on existing amazon.com cookies instead.

## Auth

- Firefox has a separate cookie jar from Chrome. **Log into amazon.com in Firefox** before testing.

## CSP / Remote Code

- Firefox's MV3 review rejects any remotely-hosted code. If the extension loads JS from `https://...`, inline it or bundle locally.

## Testing

1. Load `src/manifest.json` via `about:debugging#/runtime/this-firefox` → "Load Temporary Add-on".
2. Open the browser console (`Ctrl+Shift+J`) to watch for errors.
3. Try sending a page to Kindle; verify it arrives on your device.

## Signing / Install

- Unsigned add-ons only load temporarily (vanish on restart) on release Firefox.
- For permanent install: submit as **unlisted** on [addons.mozilla.org](https://addons.mozilla.org) — Mozilla signs it, you get a `.xpi`, only people with the direct link can install.
- Alternative: use Firefox Developer Edition / Nightly / ESR with `xpinstall.signatures.required = false` in `about:config`.
