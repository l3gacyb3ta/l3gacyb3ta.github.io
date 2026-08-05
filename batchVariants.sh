#!/bin/bash
# This script uses imagemagick to convert images in a
# folder (and it's subfolders) into smaller sized variants.

# This script was writting by Clemens Scott and tested under Ubuntu 20 LTS
# It us used in production with https://nchrs.xyz

# Use with care and backup your images!
# The repository for this script can be found at
# https://git.sr.ht/~rostiger/batchResize/

# Adapted to process one original per worker so a cold rebuild uses every core.
# Override JOBS to change the worker count (JOBS=1 restores serial behaviour).
# -----------------------------------------------------------------------------
# path where the original images are located
export SRC="${SRC:-data/original_media}"
# path where the images will be stored
export DST="${DST:-data/media}"
# sizes to convert to
SIZES=( 240 680 900 )
MAXWIDTH=1200
#dithering
COLORS=8

#imagemagick prefix
IMPREFIX="magick"

# how many originals to work on at once
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

# give each worker a single core instead of letting imagemagick oversubscribe
export MAGICK_THREAD_LIMIT=1


function resize () {

  local file="$1"

  # create output path
  local path=$(dirname "$file")   # just/the/path
  local name=$(basename "$file")  # filename.ext
  local fileBase="${name%%.*}"    # filename
  local fileExt="${name#*.}"      # ext

  # substitute source path with destination path
  # ${firstString/pattern/secondString}
  local dst="${path/$SRC/$DST}"

  # create the output path (and parents) if it doesn't exist.
  # workers race here, so a directory someone else just made is not an error
  mkdir -p "$dst" 2>/dev/null || [[ -d "$dst" ]] || return 1

  # copy the file as is if it doesn't have the right extension
  if [[ "$fileExt" != "jpg" && "$fileExt" != "jpeg" && "$fileExt" != "png" ]]; then
    cp -r "$file" "$dst" || return 1
    echo "Copied ${file}"
    return 0
  fi

  # workers interleave, so collect the progress marks and print one whole line
  local line="$file "

  # get the width of the image
  local width
  width=$($IMPREFIX identify -format "%w" "$file") || return 1

  # existing images are skipped (delete images if they were updated)
  local size output
  for size in "${SIZES[@]}"
  do
    # define output path and file
    output="$dst/$fileBase-${size}.png"
    if [[ ! -f $output ]]; then
      # resize only  if original image is greater than or equal to (ge) the current size
      if [[ $width -ge $size ]]; then
        line+="| ${size} "
        $IMPREFIX convert "$file" -strip -auto-orient -resize $size -dither FloydSteinberg -colors $COLORS "$output" || return 1
      else
        #dither only
        line+="| ${width} "
        $IMPREFIX convert "$file" -strip -auto-orient -dither FloydSteinberg -colors $COLORS "$output" || return 1
      fi
    else line+="| ----- "
    fi
  done
  # Finally also strip the original image of it's EXIF data
  # and resize it to a max width of 1200
  # keep the original format and don't dither as it will only
  # load when visitors specifically click on the image
  output="$dst/$name"
  if [[ ! -f $output ]]; then
    if [[ $width -gt $MAXWIDTH ]]; then
      line+="| ${MAXWIDTH} "
      $IMPREFIX convert "$file" -strip -auto-orient -resize $MAXWIDTH "$output" || return 1
    else
      line+="| ${width} "
      $IMPREFIX convert "$file" -strip -auto-orient "$output" || return 1
    fi
  else line+="| ----- "
  fi

  echo "${line}|"
}

# worker mode: xargs re-invokes this script once per original
if [[ "${1:-}" == "--resize-one" ]]; then
  resize "$2"
  exit $?
fi

# Security check to prevent an endless loop when
# $DST is inside $SRC (don't do that!)
if [[ "$DST" == "$SRC"/* ]]; then
  echo "DST ($DST) must not be inside SRC ($SRC)" >&2
  exit 1
fi

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# find all file in the source folder and run resize() on each, $JOBS at a time
find "$SRC" -type f -print0 | xargs -0 -n1 -P "$JOBS" "$self" --resize-one
