#!/bin/zsh
set -e

PREFIX="tesseract"
INPUT_DIR=rust
OUTPUT_DIR=Sources
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd -P)/$(basename "$OUTPUT_DIR")"

function generate_modulemap() {
  local path="$1/module.modulemap"
  local module="$2"
  local lib="$3"
  echo "module ${module} {" > "$path"
  echo "    umbrella header \"${lib}.h\"" >> "$path"
  echo "    export *" >> "$path"
  echo "}" >> "$path"
}

cd "$INPUT_DIR"

for crate in ${PREFIX}* ; do
  cargo build -p "${crate}" --release
  module_name="C${${(C)crate}//_}"
  out_dir="${OUTPUT_DIR}/${module_name}"
  cp -f "target/release/include/${crate}.h" "${out_dir}"/
  generate_modulemap "${out_dir}" "${module_name}" "${crate}"
done