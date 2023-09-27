#!/bin/zsh
set -e

MODULE_NAME="CTesseract"
MAIN_CRATE="tesseract-swift"
HEADERS_DIR="target/release/include"
OUTPUT_DIR="Sources/$MODULE_NAME/include"

DIR="$(cd "$(dirname "$0")" && pwd -P)/.."
cd "$DIR"

cargo build -p "$MAIN_CRATE" --release --all-features

rm -f "$OUTPUT_DIR"/*
cp $HEADERS_DIR/*.h "$OUTPUT_DIR/"

exit 0