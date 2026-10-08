#!/usr/bin/env bash
# Renders src/og.html to public/og.jpg (1200x630 link-preview card).
# Requires: python3, Google Chrome, npx (playwright, sharp-cli). Run after build-assets.sh if fonts were rehashed.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT=8799
TMP=$(mktemp -d)
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER; rm -rf "$TMP"' EXIT
sleep 1

npx --yes playwright screenshot --channel=chrome --viewport-size=1200,630 --wait-for-timeout=500 \
  "http://127.0.0.1:$PORT/src/og.html" "$TMP/og.png" >/dev/null
npx --yes sharp-cli@5 -i "$TMP/og.png" -o public/og.jpg -f jpeg -q 82 --mozjpeg >/dev/null
ls -l public/og.jpg
