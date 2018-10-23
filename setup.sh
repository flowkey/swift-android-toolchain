#!/usr/bin/env bash
set +e

SWIFT_VERSION="4.1.3"

function log {
    echo "[swift-android-toolchain] $*"
}

TOOLCHAIN_PATH=$(cd "$(dirname "$0")"; pwd -P)
TARGET="armv7-none-linux-androideabi"

cat > $TARGET.json <<EOF
{
    "version": 1,
    "sdk": "${TOOLCHAIN_PATH}/ndk-android-21",
    "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
    "target": "${TARGET}",
    "dynamic-library-extension": "so",
    "extra-cc-flags": [
        "-fPIC",
    ],
    "extra-cpp-flags": [
    ],
    "extra-swiftc-flags": [
        "-use-ld=gold",
        "-L${TOOLCHAIN_PATH}/ndk-android-21/usr/lib",
        "-L${TOOLCHAIN_PATH}/usr/`uname`"
    ]
}
EOF

mkdir -p $TOOLCHAIN_PATH/usr/bin

HOST_SWIFT_BIN_PATH=${HOST_SWIFT_BIN_PATH:-"/Library/Developer/Toolchains/swift-${SWIFT_VERSION}-RELEASE.xctoolchain/usr/bin"}

if [ ! -f "$HOST_SWIFT_BIN_PATH/swiftc" ]; then
    log "Couldn't find swift ${SWIFT_VERSION}"
    log "Download and install it from https://swift.org/download"
    log "e.g. for macOS: https://swift.org/builds/swift-${SWIFT_VERSION}-release/xcode/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-osx.pkg"
    log "If you have the toolchain installed at a non-standard path (e.g. on Linux), 'export HOST_SWIFT_BIN_PATH=your/path/usr/bin' and try again"
    exit 1
fi

ln -fs "$HOST_SWIFT_BIN_PATH"/swift* "$TOOLCHAIN_PATH/usr/bin"

# Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
# This allows it to find the Android swift stdlib in $TOOLCHAIN_PATH/usr/lib/swift/android
ln -f "$HOST_SWIFT_BIN_PATH/swift" "$TOOLCHAIN_PATH/usr/bin/swiftc"
