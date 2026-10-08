#!/usr/bin/env bash
# Regenerates public/fonts + public/img from src/brand and Google Fonts.
# Only needed when fonts, copy glyphs or brand images change. Outputs are committed.
# Requires: curl, uvx (fonttools), npx (sharp-cli).
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

# Basic Latin + typographic punctuation (· © ’ “ ” – — … ×)
UNICODES="U+0020-007E,U+00A0,U+00A9,U+00B7,U+00D7,U+2013,U+2014,U+2018,U+2019,U+201C,U+201D,U+2026"

# Fetch the latin-subset woff2 URL for a family/weight from the Google Fonts CSS API
gf_url() {
  curl -fsS -A "$UA" "https://fonts.googleapis.com/css2?family=$1&display=swap" |
    awk '/\/\* latin \*\//{f=1} f&&/src: url/{match($0,/https:[^)]+/);print substr($0,RSTART,RLENGTH);exit}'
}

subset() { # in out [extra args]
  local in=$1 out=$2; shift 2
  uvx --quiet --from 'fonttools[woff]' pyftsubset "$in" \
    --unicodes="$UNICODES" --flavor=woff2 --layout-features='kern,liga' \
    --no-hinting --desubroutinize --name-IDs='' --output-file="$out" "$@"
}

curl -fsS -o "$TMP/display.woff2" "$(gf_url 'Big+Shoulders+Display:wght@900')"
curl -fsS -o "$TMP/archivo.woff2" "$(gf_url 'Archivo:wght@400..800')"
for w in 400 500 600; do curl -fsS -o "$TMP/mono-$w.woff2" "$(gf_url "IBM+Plex+Mono:wght@$w")"; done

# Archivo is variable; pin to the 400–800 range we use
uvx --quiet --from 'fonttools[woff]' fonttools varLib.instancer "$TMP/archivo.woff2" wght=400:800 -o "$TMP/archivo-vf.ttf" --quiet

subset "$TMP/display.woff2" public/fonts/display-900.woff2
subset "$TMP/archivo-vf.ttf" public/fonts/archivo-var.woff2
for w in 400 500 600; do subset "$TMP/mono-$w.woff2" "public/fonts/mono-$w.woff2"; done

# Avatar: shown at ≤180 CSS px, 400px source covers ~2x
SRC=src/brand/ja-avatar-3a-400.png
npx --yes sharp-cli@5 -i "$SRC" -o public/img/avatar.avif -f avif -q 55 --effort 6 >/dev/null
npx --yes sharp-cli@5 -i "$SRC" -o public/img/avatar.webp -f webp -q 72 --effort 6 >/dev/null
npx --yes sharp-cli@5 -i "$SRC" -o public/img/avatar.jpg -f jpeg -q 72 --mozjpeg >/dev/null

# Icons (strip C2PA metadata, recompress)
npx --yes sharp-cli@5 -i src/brand/ja-favicon-32.png  -o public/favicon-32.png        -f png --compressionLevel 9 --palette >/dev/null
npx --yes sharp-cli@5 -i src/brand/ja-favicon-180.png -o public/apple-touch-icon.png  -f png --compressionLevel 9 --palette >/dev/null
npx --yes sharp-cli@5 -i src/brand/ja-favicon-512.png -o public/icon-512.png          -f png --compressionLevel 9 --palette >/dev/null
sed 's/<metadata>.*<\/metadata>//; s/ xmlns:c2pa="[^"]*"//' src/brand/ja-monogram-on-ink.svg > public/favicon.svg

# Content-hash fonts + images (served immutable, see public/_headers) and rewrite refs in index.html + og.html
for f in public/fonts/*.woff2 public/img/*.*; do
  base=$(basename "$f"); stem=${base%%.*}; ext=${base##*.}
  [[ $base =~ ^[^.]+\.[0-9a-f]{8}\.[a-z0-9]+$ ]] && continue  # already hashed (old output)
  hash=$(shasum -a 256 "$f" | cut -c1-8)
  dir=$(dirname "$f")
  find "$dir" -name "$stem.*.$ext" -delete
  mv "$f" "$dir/$stem.$hash.$ext"
  sed -E -i '' "s#/${dir#public/}/$stem(\.[0-9a-f]{8})?\.$ext#/${dir#public/}/$stem.$hash.$ext#g" public/index.html src/og.html
done

ls -l public/fonts public/img public/*.png public/*.svg
