#!/bin/zsh
set -e

DIR="$(cd "$(dirname "$0")" && pwd -P)/.."
ZIP_PATH=$([ -n "$1" ] && echo "$DIR/$1" || echo "$DIR/Tesseract-Core.bin.zip")
rm -f "$ZIP_PATH"
cd "$DIR"

Rust/generate_headers.sh
Rust/generate_xcframework.sh

TMPDIR=$(mktemp -d)

cp LICENSE "$TMPDIR/"
mkdir "$TMPDIR/Sources"
cp -r Sources/CTesseract "$TMPDIR/Sources/"
cp -r *.xcframework "$TMPDIR/"

cd "$TMPDIR"
zip -r "${ZIP_PATH}" *.xcframework LICENSE Sources

rm -rf "$TMPDIR"

exit 0