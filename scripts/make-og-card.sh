#!/usr/bin/env bash
# Render the Open Graph card: og/card.html -> static/og.png (1200x630).
#
# The card is a PRE-RENDERED, committed asset. Zola never builds it (it only
# builds content/ and copies static/), so there is no Chromium in the Nix
# build. Re-run this whenever og/card.html or static/avatar.jpg changes, then
# commit the new static/og.png.
#
#   ./scripts/make-og-card.sh
#   CHROMIUM=/path/to/chromium ./scripts/make-og-card.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${here}/static/og.png"
bin="${CHROMIUM:-chromium}"

command -v "${bin}" >/dev/null || {
  echo "error: '${bin}' not found (set CHROMIUM=/path/to/chromium)" >&2
  exit 1
}

profile="$(mktemp -d)"

"${bin}" \
  --headless=new \
  --no-sandbox \
  --disable-gpu \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --user-data-dir="${profile}" \
  --window-size=1200,630 \
  --screenshot="${out}" \
  "file://${here}/og/card.html" 2>/dev/null

rm -rf "${profile}"

# Confirm we actually got a 1200x630 PNG and not an error page.
if ! head -c 8 "${out}" | od -An -tx1 | tr -d ' \n' | grep -q '^89504e47'; then
  echo "error: ${out} is not a PNG" >&2
  exit 1
fi

echo "wrote ${out}"