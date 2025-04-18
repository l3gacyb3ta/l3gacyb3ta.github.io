#!/bin/bash
# This script uses imagemagick to convert images in a 
# folder (and it's subfolders) into smaller sized variants.

# This script was writting by Clemens Scott and tested under Ubuntu 20 LTS
# It us used in production with https://nchrs.xyz

# Use with care and backup your images!
# The repository for this script can be found at
# https://git.sr.ht/~rostiger/batchResize/
# -----------------------------------------------------------------------------
# path where the original images are located
SRC="data/original_media"
# path where the images will be stored
DST="data/media"
# sizes to convert to
SIZES=( 240 680 900 )
MAXWIDTH=1200
#dithering
COLORS=8

#imagemagick prefix
IMPREFIX="magick"


function resize () {
    
  # Security check to prevent an endless loop when
  # $DST is inside $SRC (don't do that!) 
  [[ $file == *"${DST}/*"* ]] && continue 

  for file in $1
  do
    # skip file if it doesn't exist
  	[ -f "$file" ] || continue

    # create output path
    path=$(dirname $file)   # just/the/path    
    name=$(basename $file)  # filename.ext
    fileBase="${name%%.*}"  # filename
    fileExt="${name#*.}"    # ext

    # substitute source path with destination path
    # ${firstString/pattern/secondString}
    dst="${path/$SRC/$DST}"    

    # existing images are skipped (delete images if they were updated)    
    # create the output path (and parents) if it doesn't exist
    if [[ ! -d "$dst" ]]; then 
      mkdir -p $dst
    fi
		
    # copy the file as is if it doesn't have the right extension
    if [[ "$fileExt" != "jpg" && "$fileExt" != "jpeg" && "$fileExt" != "png" ]]; then
			cp -r $file $dst
   		echo "Copied ${file}"
			continue
    fi

    # create smaller sizes for responsive image selection
    echo $file
    # get the width of the image
    width=$($IMPREFIX identify -format "%w" "$file")> /dev/null
  	for size in "${SIZES[@]}"
  	do
      # define output path and file
	    output="$dst/$fileBase-${size}.png"
      if [[ ! -f $output ]]; then
        # resize only  if original image is greater than or equal to (ge) the current size
        if [[ $width -ge $size ]]; then
          echo -n "| ${size} "
  			  $IMPREFIX convert $file -strip -auto-orient -resize $size -dither FloydSteinberg -colors $COLORS $output
        else
        	#dither only
          echo -n "| ${width} "
  			  $IMPREFIX convert $file -strip -auto-orient -dither FloydSteinberg -colors $COLORS $output
  		  fi
      else echo -n "| ----- "
      fi
    done
    # Finally also strip the original image of it's EXIF data
    # and resize it to a max width of 1200
    # keep the original format and don't dither as it will only 
    # load when visitors specifically click on the image
    output="$dst/$name"
    if [[ ! -f $output ]]; then
    	if [[ $width -gt $MAXWIDTH ]]; then
      	$IMPREFIX convert $file -strip -auto-orient -resize $MAXWIDTH $output
      	echo -n "| ${MAXWIDTH} "
      else
      	$IMPREFIX convert $file -strip -auto-orient $output
      	echo -n "| ${width} "
      fi
    else echo -n "| ----- "
    fi
    echo -en "|\n"
  done
}

# find all file in the source folder and run resize() on each
find $SRC | while read file; do resize "${file}"; done
