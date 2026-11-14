#!/bin/bash
# Makes cover.jpg for this post: a Half-Life 2 screenshot with the title text on it.
# Needs ImageMagick 7 (magick) and the Noto Sans Black font (Fedora: google-noto-sans-fonts).
#
# Usage: ./cover.sh [screenshot.png] [output.jpg]
#   default screenshot: the HDMI capture from ~/code/linux-drm-jh7110/shots/
#   default output:     cover.jpg next to this script
# The "just another devops guy" logo goes in the bottom right corner (LOGO=... to use another file).
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
SRC=${1:-$HOME/code/linux-drm-jh7110/shots/phase-e-hl2-timedemo-hdmi-audio.png}
OUT=${2:-$DIR/cover.jpg}
LOGO=${LOGO:-$HOME/Dropbox/obs/just another devops guy/Logo devops guy 1.02 with foto.png}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
F=/usr/share/fonts/google-noto/NotoSans-Black.ttf
NAVY='#1b2550'
YEL='#f6b51e'

args=()
# text with a navy outline: x y size color outline-width text
txt() {
	args+=(-font "$F" -pointsize "$3" -stroke "$NAVY" -strokewidth "$5" -fill "$NAVY" -annotate "+$1+$2" "$6"
		-stroke none -fill "$4" -annotate "+$1+$2" "$6")
}
txt 40 150 112 white 18 "HALF-LIFE 2"
txt 44 235 62 "$YEL" 14 "on the onboard GPU"
# white box with the board name
args+=(-fill white -stroke "$NAVY" -strokewidth 8 -draw "roundrectangle 40,270 700,365 22,22")
args+=(-stroke none -font "$F" -pointsize 58 -fill "$NAVY" -annotate +66+340 "StarFive VisionFive 2")
# navy label with the GPU name
args+=(-fill "$NAVY" -draw "roundrectangle 40,385 460,455 18,18")
args+=(-font "$F" -pointsize 40 -fill "$YEL" -annotate +64+436 "PowerVR BXE-4-32")

# logo: drop the small stray specks around it (alpha blobs < 2000 px), trim, scale to 215 px high
magick "$LOGO" -alpha extract -threshold 10% -define connected-components:area-threshold=2000 \
	-define connected-components:mean-color=true -connected-components 8 "$TMP/mask.png" 2>/dev/null
magick "$LOGO" \( +clone -alpha extract \) "$TMP/mask.png" -delete 0 -compose multiply -composite "$TMP/alpha.png" 2>/dev/null
magick "$LOGO" "$TMP/alpha.png" -alpha off -compose copy_opacity -composite -trim +repage -depth 8 \
	-resize x215 "$TMP/logo.png" 2>/dev/null

magick "$SRC" "${args[@]}" "$TMP/logo.png" -gravity southeast -geometry +36+18 -compose over -composite \
	-quality 88 "$OUT"
echo "written: $OUT"
