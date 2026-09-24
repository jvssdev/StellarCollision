#!/usr/bin/env bash
# Decode binary clipboard images to /tmp/cliphist for preview in the UI.
# Output: ID \t DISPLAY_TEXT [\t /path/to/image]

tmp_dir="/tmp/cliphist"
mkdir -p "$tmp_dir"

if ! command -v cliphist >/dev/null 2>&1; then
  exit 0
fi

# Plain list if no awk available
if ! command -v gawk >/dev/null 2>&1 && ! command -v awk >/dev/null 2>&1; then
  cliphist list
  exit 0
fi

AWK_BIN="$(command -v gawk 2>/dev/null || command -v awk)"

cliphist list | "$AWK_BIN" -v tmp="$tmp_dir" '
BEGIN { FS="\t"; OFS="\t" }
{
    if ($2 ~ /\[\[.*binary.*(jpg|jpeg|png|bmp|webp)/) {
        ext = "png"
        if (match($2, /jpg|jpeg|png|bmp|webp/)) {
            ext = substr($2, RSTART, RLENGTH)
        }
        img_path = tmp "/" $1 "." ext

        if (system("test -s \"" img_path "\"") != 0) {
            cmd = "cliphist decode > \"" img_path "\""
            print $0 | cmd
            close(cmd)
        }

        print $1, $2, img_path
    } else {
        print $0
    }
}'
