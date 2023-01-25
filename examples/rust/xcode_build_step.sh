#!/bin/bash
set -e

MODULE_NAME="$1"
C_LIB_NAME="$2"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HAS_CARGO_IN_PATH=`command -v cargo >/dev/null 2>&1; echo $?`

if [ "${HAS_CARGO_IN_PATH}" -ne "0" ]; then
    source $HOME/.cargo/env
fi

ROOT_DIR="${SCRIPT_DIR}"

if [[ "${CONFIGURATION}" == "Release" ]]; then
  RELEASE="--release"
else
  RELEASE=""
fi

if [[ -n "${DEVELOPER_SDK_DIR:-}" && "$PLATFORM_NAME" != "macosx" ]]; then
  # We're in Xcode, and we're cross-compiling.
  # In this case, we need to add an extra library search path for build scripts and proc-macros,
  # which run on the host instead of the target.
  # (macOS Big Sur does not have linkable libraries in /usr/lib/.)
  # We are adding it by providing Clang variable.
  # Cargo can't pass any meaningfull conpiler variables to build scripts when cross-compiling.
  export LIBRARY_PATH="${DEVELOPER_SDK_DIR}/MacOSX.sdk/usr/lib:${LIBRARY_PATH:-}"
  # And set library path back for our targets (or it will link with macOS system libraries)
  # we can't avoid it because we can't path build script specific configuration to Cargo
  export RUSTFLAGS="-L${SDKROOT}/usr/lib"
fi

function get_platform_triplet() {
  local arch="$1"
  local platform="$2"
  if [[ "${arch}" == "arm64" ]]; then
    arch="aarch64"
  fi
  case "${platform}" in
    macosx)
      echo "${arch}-apple-darwin"
    ;;
    iphoneos)
      echo "${arch}-apple-ios"
    ;;
    iphonesimulator)
      if [[ "${arch}" == "aarch64" ]]; then
        echo "aarch64-apple-ios-sim"
      else
        echo "${arch}-apple-ios"
      fi
    ;;
    appletvos | appletvsimulator)
      echo "tvOS is unsupported"
      exit 1
    ;;
    watchos | watchsimulator)
      echo "watchOS is unsupported"
      exit 1
    ;;
    *)
      echo "Unknown platform: ${platform}"
      exit 1
    ;;
  esac
}

function generate_modulemap() {
  local path="$1/module.modulemap"
  local module="$2"
  local lib="$3"
  echo "module ${module} {" > "$path"
  echo "    umbrella header \"${lib}.h\"" >> "$path"
  echo "    link \"${lib}\"" >> "$path"
  echo "    export *" >> "$path"
  echo "}" >> "$path"
}

OUTPUT_DIR=`echo "${CONFIGURATION}" | tr '[:upper:]' '[:lower:]'`

cd "${ROOT_DIR}"

rm -rf "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"

BUILT_LIBS=""
for arch in $ARCHS; do
  TTRIPLET=$(get_platform_triplet $arch $PLATFORM_NAME)
  cargo build -p $C_LIB_NAME --lib $RELEASE --target ${TTRIPLET}
  BUILT_LIBS="${BUILT_LIBS} ${ROOT_DIR}/target/${TTRIPLET}/${OUTPUT_DIR}/lib${C_LIB_NAME}.a"
done

BUILT_LIBS="${BUILT_LIBS:1}"

lipo ${BUILT_LIBS} -create -output "${CONFIGURATION_BUILD_DIR}/lib${C_LIB_NAME}.a"

cp -f "${ROOT_DIR}/target/${OUTPUT_DIR}/include/${C_LIB_NAME}.h" "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/

generate_modulemap "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}" $MODULE_NAME $C_LIB_NAME

exit 0
