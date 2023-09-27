#!/bin/zsh
set -e

HEADERS_FRAMEWORK_NAME="CTesseract"
XCFRAMEWORK_NAME="${HEADERS_FRAMEWORK_NAME}Bin"
LIBRARY_NAME="tesseract_swift"

DIR="$(cd "$(dirname "$0")" && pwd -P)"
SOURCES_DIR="${DIR}/.."
OUTPUT_DIR="${DIR}/.."

# Removed tvOS targets for now. Should be added when tvOS will have Tier 2 support.
#  'tvos::arm64:aarch64-apple-tvos'
#  'tvos:simulator:arm64,x86_64:aarch64-apple-tvos,x86_64-apple-tvos'
# Removed macOS target for now. We don't have transports for it
#  'macos::arm64,x86_64:aarch64-apple-darwin,x86_64-apple-darwin'
readonly BUILD_TARGETS=(
  'ios::arm64:aarch64-apple-ios'
  'ios:simulator:arm64,x86_64:aarch64-apple-ios-sim,x86_64-apple-ios'
)

readonly SDK_MAPPINGS=(
  'ios-:iphoneos'
  'ios-simulator:iphonesimulator'
  'tvos-:appletvos'
  'tvos-simulator:appletvsimulator'
  'watchos-:watchos'
  'watchos-simulator:watchsimulator'
  'macos-:macosx'
)

function get_sdk_name() {
  local plt=$1
  local vart=$2
  for mapping in "${SDK_MAPPINGS[@]}"; do
      IFS=: read -r platform sdk <<< "$mapping"
      if [[ "$platform" == "$plt-$vart" ]]; then
        echo "$sdk"
        break
      fi
  done
}

function get_platform_identifier() {
  local platform=$1
  local arch=${2//,/_}
  local variant=$3
  
  local IDENTIFIER="${platform}-${arch}"
  if [ -n "${variant}" ]; then
    IDENTIFIER="${IDENTIFIER}-${variant}"
  fi
  echo "${IDENTIFIER}"
}

function generate_modulemap() {
  local path="$1/module.modulemap"
  local module="$2"
  local lib="$3"
  echo "module ${module} {" > "$path"
  echo -e "\tumbrella header \"${lib}.h\"" >> "$path"
  echo -e "\tlink \"${lib}\"" >> "$path"
  echo -e "\texport *" >> "$path"
  echo "}" >> "$path"
}

function generate_umbrella_header() {
  local path="$1/$3.h"
  local module=$2 
  echo "#pragma once" > "$path"
  echo "// reimporting headers framework" >> "$path"
  echo "@import ${module};" >> "$path"
}

function print_xcframework_header() {
  echo '<?xml version="1.0" encoding="UTF-8"?>' > $1
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $1
  echo '<plist version="1.0">' >> $1
  echo '<dict>' >> $1
  echo -e '\t<key>AvailableLibraries</key>' >> $1
  echo -e '\t<array>' >> $1
}

function print_xcframework_footer() {
  echo -e '\t</array>' >> $1
  echo -e '\t<key>CFBundlePackageType</key>' >> $1
  echo -e '\t<string>XFWK</string>' >> $1
  echo -e '\t<key>XCFrameworkFormatVersion</key>' >> $1
  echo -e '\t<string>1.0</string>' >> $1
  echo '</dict>' >> $1
  echo '</plist>' >> $1
}

function print_xcframework_library() {
  local file=$1
  local name=$2
  local platform=$3
  local arch=$4
  local variant=$5
  local identifier=$(get_platform_identifier "${platform}" "$arch" "$variant")
  local archs=(${(@s:,:)arch})
  echo -e "\t<dict>" >> $file
  echo -e "\t\t<key>HeadersPath</key>" >> $file
  echo -e "\t\t<string>Headers</string>" >> $file
  echo -e "\t\t<key>LibraryIdentifier</key>" >> $file
  echo -e "\t\t<string>${identifier}</string>" >> $file
  echo -e "\t\t<key>LibraryPath</key>" >> $file
  echo -e "\t\t<string>${name}</string>" >> $file
  echo -e "\t\t<key>SupportedArchitectures</key>" >> $file
  echo -e "\t\t<array>" >> $file
  for arch in "${archs[@]}" ; do
    echo -e "\t\t\t<string>${arch}</string>" >> $file
  done
  echo -e "\t\t</array>" >> $file
  echo -e "\t\t<key>SupportedPlatform</key>" >> $file
  echo -e "\t\t<string>${platform}</string>" >> $file
  if [ -n "${variant}" ]; then
    echo -e "\t\t<key>SupportedPlatformVariant</key>" >> $file
    echo -e "\t\t<string>${variant}</string>" >> $file
  fi
  echo -e "\t</dict>" >> $file
}

function add_library_to_xcframework() {
  local fmwk_path=$1
  local headers=$2
  local lib_path=$3
  local platform=$4
  local arch=$5
  local variant=$6
  local identifier=$(get_platform_identifier "${platform}" "$arch" "$variant")
  local out="${fmwk_path}/${identifier}"
  local lib=$(basename "${lib_path}")
  mkdir -p "${out}"/Headers
  cp -rf "${headers}"/ "${out}"/Headers/
  cp -f "${lib_path}" "${out}"/
  print_xcframework_library "${fmwk_path}/Info.plist" "${lib}" "${platform}" "${arch}" "${variant}"
}

# Load cargo env if needed
HAS_CARGO_IN_PATH=`command -v cargo >/dev/null 2>&1; echo $?`
if [ "${HAS_CARGO_IN_PATH}" -ne 0 ]; then
    source $HOME/.cargo/env
fi

# Debug or release build
if [[ "$1" == "debug" ]]; then
  RELEASE=""
  CONFIGURATION="debug"
else
  RELEASE="--release"
  CONFIGURATION="release"
fi

# output xcframework path
XCFRAMEWORK_PATH="${OUTPUT_DIR}/${XCFRAMEWORK_NAME}.xcframework"

# recreate franework folder
rm -rf "${XCFRAMEWORK_PATH}"
mkdir -p "${XCFRAMEWORK_PATH}"

cd "${SOURCES_DIR}"

RUST_TARGET_DIR="${SOURCES_DIR}/target"
HEADERS_DIR="${RUST_TARGET_DIR}/universal/include"
OUT_LIB_PATH="${RUST_TARGET_DIR}/universal/lib${LIBRARY_NAME}.a"

# Print plist header.
print_xcframework_header "${XCFRAMEWORK_PATH}/Info.plist"

for btarget in ${BUILD_TARGETS[@]}; do
  IFS=: read -r platform variant archs targets <<< "$btarget"
  
  local sdk_name=$(get_sdk_name "$platform" "$variant")
  echo "Building for: ${sdk_name}..."

  rm -rf "${HEADERS_DIR}"
  mkdir -p "${HEADERS_DIR}"
  mkdir -p "$(dirname "${OUT_LIB_PATH}")"

  local built_libs=()
  targets=(${(@s:,:)targets})

  for target in ${targets[@]}; do
    echo "Building target: ${target}..."
    cargo build --lib $RELEASE --target $target --all-features
    built_libs+=("${RUST_TARGET_DIR}/${target}/${CONFIGURATION}/lib${LIBRARY_NAME}.a")
  done
  
  lipo ${built_libs} -create -output "${OUT_LIB_PATH}"

  generate_modulemap "${HEADERS_DIR}" "${XCFRAMEWORK_NAME}" "${LIBRARY_NAME}"
  generate_umbrella_header "${HEADERS_DIR}" "${HEADERS_FRAMEWORK_NAME}" "${LIBRARY_NAME}"
  
  add_library_to_xcframework "${XCFRAMEWORK_PATH}" \
    "${HEADERS_DIR}/" "${OUT_LIB_PATH}" \
    "${platform}" "${archs}" "${variant}"
  
  # cleanup
  rm -rf "${HEADERS_DIR}"
  rm -f "${OUT_LIB_PATH}"
done

print_xcframework_footer "${XCFRAMEWORK_PATH}/Info.plist"

exit 0