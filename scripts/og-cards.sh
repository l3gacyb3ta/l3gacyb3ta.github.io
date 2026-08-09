#!/bin/bash
# Generate 1200x630 Open Graph title cards for blog posts.
#
# Reads out/posts.json (emitted by aethopica), writes out/media/og/<rkey>.png
# plus a default.png used by pages without header art. Runs after the site
# build. Requires ImageMagick (magick or convert) and python3.

set -e

OUT="${OUT:-out}"
OG="$OUT/media/og"
ICON="${ICON:-data/original_media/icon/icon-512.png}"
SITE="arcades.agency"

if command -v magick >/dev/null 2>&1; then IM=magick; else IM=convert; fi

# DejaVu on the CI runners; font files directly on macOS
if $IM -list font 2>/dev/null | grep -q "Font: DejaVu-Sans$"; then
  SANS="DejaVu-Sans"; MONO="DejaVu-Sans-Mono"
elif [ -f /System/Library/Fonts/Helvetica.ttc ]; then
  SANS="/System/Library/Fonts/Helvetica.ttc"
  MONO="/System/Library/Fonts/Menlo.ttc"
else
  echo "no usable font found for $IM" >&2; exit 1
fi

INK="#0a0a0a"
FAINT="#666666"

mkdir -p "$OG"

# card DEST TITLE FOOTER-RIGHT [TITLESIZE]
card () {
  local dest="$1" title="$2" right="$3" size="${4:-72}"
  $IM -size 1200x630 xc:white \
    \( -size 1040x380 -background white -fill "$INK" -font "$SANS" \
       -pointsize "$size" -gravity northwest caption:"$title" \) \
    -gravity northwest -geometry +80+120 -composite \
    \( "$ICON" -filter point -resize 56x56 \) -gravity northwest -geometry +80+494 -composite \
    -font "$MONO" -pointsize 28 -fill "$FAINT" \
    -gravity northwest -annotate +156+508 "$SITE" \
    -gravity northeast -annotate +80+508 "$right" \
    -fill "$INK" -draw "rectangle 80,88 1120,92" \
    "$dest"
  echo "og card: $dest"
}

card "$OG/default.png" "aethopica" "the wiki of Arcade Wise"

python3 -c '
import json, sys
for p in json.load(open(sys.argv[1]))["posts"]:
    print("\t".join([p["rkey"], p["title"], p["publishedAt"][:10]]))
' "$OUT/posts.json" |
while IFS=$'\t' read -r rkey title date; do
  card "$OG/$rkey.png" "$title" "$date"
done
