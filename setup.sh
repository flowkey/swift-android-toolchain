#!/usr/bin/env bash
set +e

SWIFT_VERSION="swift-DEVELOPMENT-SNAPSHOT-2019-07-30-a"

function log {
    echo "[swift-android-toolchain] $*"
}

TOOLCHAIN_PATH=$(cd "$(dirname "$0")"; pwd -P)
ANDROID_SDK="${ANDROID_SDK:-${TOOLCHAIN_PATH}/Android.sdk}"
TOOLCHAIN_BIN_DIR="${ANDROID_SDK}/usr/bin"

sed -i -e s~C:/Microsoft/AndroidNDK64/android-ndk-r16b~${ANDROID_NDK_PATH}~g ${ANDROID_SDK}/usr/lib/swift/android/armv7/glibc.modulemap

mkdir -p "${TOOLCHAIN_BIN_DIR}"

HOST_SWIFT_BIN_PATH=${HOST_SWIFT_BIN_PATH:-"/Library/Developer/Toolchains/${SWIFT_VERSION}.xctoolchain/usr/bin"}

if [ ! -f "$HOST_SWIFT_BIN_PATH/swiftc" ]; then
    log "Couldn't find swift ${SWIFT_VERSION}"
    log "Download and install it from https://swift.org/download"
    log "If you have the toolchain installed at a non-standard path (e.g. on Linux), 'export HOST_SWIFT_BIN_PATH=your/path/usr/bin' and try again"
    exit 1
fi

ln -fs "$HOST_SWIFT_BIN_PATH"/swift* "${TOOLCHAIN_BIN_DIR}"

# Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
# This allows it to find the Android swift stdlib in ${TOOLCHAIN_PATH}/usr/lib/swift/android
ln -f "$HOST_SWIFT_BIN_PATH/swift" "${TOOLCHAIN_BIN_DIR}/swiftc"
