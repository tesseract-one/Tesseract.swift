#!/bin/zsh
set -e

CRATES=("tesseract-swift-utils" "tesseract-swift-transport")
MODULE_NAME="CTesseractShared"
OUTPUT_DIR="Sources/$MODULE_NAME/include"

DIR="$(cd "$(dirname "$0")" && pwd -P)"

cd "$DIR/.."

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for crate in $CRATES; do
  cbindgen -q --crate $crate -o "$OUTPUT_DIR/$crate.h"
done

exit 0
