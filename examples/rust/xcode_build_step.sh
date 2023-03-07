#!/bin/bash
set -e

MODULE_NAME="$1"
C_LIB_NAME="$2"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${SCRIPT_DIR}"

# rustc chooses the SDK with `xcrun --show-sdk-path -sdk macosx` and `xcrun --show-sdk-path -sdk iphoneos` for macros and regular crates respectively.
# We need to help it though, by cleaning up the ENV mess XCode pushes to us
# Note that default SDK will be used for macOS and iOS. We can't select SDK version
ALLOWED_ENV_VARS="^PATH$|^SHELL$|^PWD$|^LOGNAME$|^HOME$|^TMPDIR$|^USER$|^SRCROOT$|^CONFIGURATION_BUILD_DIR$"
ALLOWED_ENV_VARS="$ALLOWED_ENV_VARS|^CONFIGURATION$|^ARCHS$|^PLATFORM_NAME$|^DEVELOPER_DIR$"
unset $(env | cut -d= -f1 | egrep -v "$ALLOWED_ENV_VARS")
export PATH="$(echo $PATH | tr ':' '\n' | egrep -v 'platform|xctoolchain' | tr '\n' ':')"

# check that we have cargo. If not - import cargo env
HAS_CARGO_IN_PATH=$(command -v cargo >/dev/null 2>&1; echo $?)
if [[ "${HAS_CARGO_IN_PATH}" != "0" ]]; then
    source "$HOME/.cargo/env"
fi

if [[ "${CONFIGURATION}" == "Release" ]]; then
  RELEASE="--release"
else
  RELEASE=""
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
  {
    echo "module ${module} {"
    echo "    umbrella header \"${lib}.h\""
    echo "    link \"${lib}\""
    echo "    export *"
    echo "}"
  } > "$path"
}

OUTPUT_DIR=$(echo "${CONFIGURATION}" | tr '[:upper:]' '[:lower:]')

cd "${ROOT_DIR}"

rm -rf "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"

BUILT_LIBS=""
for arch in $ARCHS; do
  TTRIPLET=$(get_platform_triplet $arch $PLATFORM_NAME)
  cargo build -p $C_LIB_NAME --lib $RELEASE --target $TTRIPLET
  BUILT_LIBS="${BUILT_LIBS} ${ROOT_DIR}/target/${TTRIPLET}/${OUTPUT_DIR}/lib${C_LIB_NAME}.a"
done

BUILT_LIBS="${BUILT_LIBS:1}"

lipo ${BUILT_LIBS} -create -output "${CONFIGURATION_BUILD_DIR}/lib${C_LIB_NAME}.a"

cp -f "${ROOT_DIR}/target/${OUTPUT_DIR}/include/${C_LIB_NAME}.h" "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/

generate_modulemap "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}" $MODULE_NAME $C_LIB_NAME

exit 0
