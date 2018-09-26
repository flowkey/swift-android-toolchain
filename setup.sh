#!/bin/sh
set +e

function log {
    echo "[swift-mac-toolchain setup] $*"
}

TOOLCHAIN_PATH=$(cd "$(dirname "$0")"; pwd -P)
TARGET="armv7-none-linux-androideabi"

# exit if setup files exist already
if [ -f ./$TARGET.json ] && [ -d ./usr/bin ] && [ "$1" != "-f" ]; then
    exit 0;
fi

log "Creating $TARGET.json"
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
        "-L${TOOLCHAIN_PATH}/usr/Darwin"
    ]
}
EOF

log "Linking locally-installed swift version into the toolchain path"

mkdir -p $TOOLCHAIN_PATH/usr/bin

HOST_SWIFT_BIN_PATH=${HOST_SWIFT_BIN_PATH:-$(dirname `xcrun --find swift`)}
ln -fs "$HOST_SWIFT_BIN_PATH"/* "$TOOLCHAIN_PATH/usr/bin"

# Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
# This allows it to find the Android swift stdlib in $TOOLCHAIN_PATH/usr/lib/swift/android
ln -f "$HOST_SWIFT_BIN_PATH/swift" "$TOOLCHAIN_PATH/usr/bin/swiftc"

log "Setup complete"
