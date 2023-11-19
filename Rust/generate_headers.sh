#!/bin/zsh
set -e

MODULE_NAME="CTesseractShared"
MAIN_CRATE="tesseract-swift-transports"
HEADERS=("tesseract-swift-utils.h" "tesseract-swift-transports.h")
HEADERS_DIR="target/release/include"
OUTPUT_DIR="Sources/$MODULE_NAME/include"

DIR="$(cd "$(dirname "$0")" && pwd -P)/.."
cd "$DIR"

cargo build -p "$MAIN_CRATE" --release --all-features

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for header in "${HEADERS[@]}"; do
  cp "$HEADERS_DIR/$header" "$OUTPUT_DIR/"
done

exit 0
