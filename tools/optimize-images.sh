#!/bin/bash
#
# Convert generated source images into web-ready assets.
#
#   1. Drop whatever your image generator produced (PNG/JPEG, any size) into
#      images/src/  using the target filename, e.g. images/src/hero-plumbing.png
#   2. Run:  ./tools/optimize-images.sh
#   3. Optimised .webp files land in images/ and are what the pages reference.
#
# images/src/ is excluded from the S3 sync, so the heavy originals stay local
# while only the compressed output ships. Requires ImageMagick (`brew install
# imagemagick`).
#
# Aspect ratio is deliberately NOT forced: every hero and tile is painted with
# `background-size: cover` or `object-fit: cover`, so the browser crops to fit.
# Cropping here would only throw away pixels.

set -e
cd "$(dirname "$0")/.."

command -v magick >/dev/null 2>&1 || { echo "❌ ImageMagick not found. brew install imagemagick"; exit 1; }

mkdir -p images/src

# Sweep stray originals out of images/ root first. Only optimised .webp and the
# rendered card-*.jpg belong there — anything else is a freshly generated file
# dropped in the obvious place, so move it rather than making the user do it.
moved=0
while IFS= read -r stray; do
    mv "$stray" images/src/
    echo "  moved $(basename "$stray") → images/src/"
    moved=$((moved + 1))
done < <(find images -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
            ! -name 'card-*')
[ "$moved" -gt 0 ] && echo ""

shopt -s nullglob nocaseglob
sources=(images/src/*.png images/src/*.jpg images/src/*.jpeg images/src/*.webp)
shopt -u nocaseglob

if [ ${#sources[@]} -eq 0 ]; then
    echo "No source images in images/src/ — nothing to do."
    echo "Drop generated files there named hero-<brand>.png, brew-<item>.png, life-<item>.png"
    exit 0
fi

# Heroes are full-bleed backgrounds, so they get the full cap. Product tiles render
# in a 3-column grid inside a 1200px container — about 350px each — so 900px is
# already generous at 2x DPR and anything larger is wasted bytes.
hero_width=2560
tile_width=900

converted=0
for src in "${sources[@]}"; do
    base=$(basename "$src")
    name="${base%.*}"
    out="images/${name}.webp"

    case "$name" in
        hero-*) max=$hero_width; q=80 ;;
        *)      max=$tile_width; q=82 ;;
    esac

    # '>' only shrinks — a source smaller than the cap is left at its own size.
    magick "$src" -resize "${max}x${max}>" -strip -quality "$q" -define webp:method=6 "$out"

    in_kb=$(( $(wc -c < "$src") / 1024 ))
    out_kb=$(( $(wc -c < "$out") / 1024 ))
    dims=$(magick identify -format "%wx%h" "$out")
    printf "  %-28s %5s KB → %5s KB  (%s)\n" "$name.webp" "$in_kb" "$out_kb" "$dims"
    converted=$((converted + 1))
done

echo ""
echo "✅ $converted image(s) optimised into images/"
