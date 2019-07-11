#!/usr/bin/env bash
set +e

SWIFT_VERSION="swift-DEVELOPMENT-SNAPSHOT-2019-07-09-a"

function log {
    echo "[swift-android-toolchain] $*"
}

TOOLCHAIN_PATH=$(cd "$(dirname "$0")"; pwd -P)
TARGET="armv7-none-linux-androideabi"
TOOLCHAIN_BIN_DIR="${TOOLCHAIN_PATH}/Android.sdk/usr/bin"

cat > $TARGET.json <<EOF
{
    "version": 1,
    "sdk": "${TOOLCHAIN_PATH}/ndk-android-21",
    "toolchain-bin-dir": "${TOOLCHAIN_BIN_DIR}",
    "target": "${TARGET}",
    "dynamic-library-extension": "so",
    "extra-cc-flags": [
        "-fPIC",
    ],
    "extra-cpp-flags": [
    ],
    "extra-swiftc-flags": [
        "-use-ld=lld",
    ]
}
EOF

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
