#!/bin/bash
# Generate 1200x630 Open Graph title cards for blog posts.
#
# Reads out/posts.json (emitted by aethopica), writes out/media/og/<rkey>.jpg
# plus a default.jpg used by pages without header art. Runs after the site
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
    -quality 90 "$dest"
  echo "og card: $dest"
}

# headercard DEST HEADER-IMG TITLE DATE
# header art cover-cropped above a title bar: arch, title, date.
# text uses west/east gravity so everything shares the bar's centerline
# (570): offset 255 = 570 - canvas middle (315)
headercard () {
  local dest="$1" img="$2" title="$3" date="$4"
  $IM -size 1200x630 xc:white \
    \( "$img" -resize 1200x506^ -gravity center -extent 1200x506 \) \
    -gravity northwest -geometry +0+0 -composite \
    -fill "$INK" -draw "rectangle 0,506 1200,510" \
    \( "$ICON" -filter point -resize 56x56 \) -gravity northwest -geometry +40+542 -composite \
    -font "$SANS" -pointsize 36 -fill "$INK" \
    -gravity west -annotate +116+255 "$title" \
    -font "$MONO" -pointsize 28 -fill "$FAINT" \
    -gravity east -annotate +40+259 "$date" \
    -quality 90 "$dest"
  echo "og card: $dest (header)"
}

# the post's header art, if any: the stripped original batchVariants
# leaves in data/media/headers
header_for () {
  local rkey="$1" ext
  for ext in jpg jpeg png; do
    if [ -f "data/media/headers/$rkey.$ext" ]; then
      echo "data/media/headers/$rkey.$ext"; return
    fi
  done
}

card "$OG/default.jpg" "aethopica" "the wiki of Arcade Wise"

python3 -c '
import json, sys
for p in json.load(open(sys.argv[1]))["posts"]:
    print("\t".join([p["rkey"], p["title"], p["publishedAt"][:10]]))
' "$OUT/posts.json" |
while IFS=$'\t' read -r rkey title date; do
  header="$(header_for "$rkey")"
  if [ -n "$header" ]; then
    headercard "$OG/$rkey.jpg" "$header" "$title" "$date"
  else
    card "$OG/$rkey.jpg" "$title" "$date"
  fi
done
