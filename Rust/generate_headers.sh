#!/bin/zsh
set -e

MODULE_NAME="CTesseractShared"
MAIN_CRATE="tesseract-swift-transport"
HEADERS_DIR="target/release/include"
OUTPUT_DIR="Sources/$MODULE_NAME/include"

DIR="$(cd "$(dirname "$0")" && pwd -P)/.."
cd "$DIR"

rm -rf "$HEADERS_DIR"

cargo build -p "$MAIN_CRATE" --release --all-features

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp "$HEADERS_DIR/"*.h "$OUTPUT_DIR/"

exit 0
