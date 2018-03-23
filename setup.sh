#!/bin/sh
set +e

function log {
    echo "[swift-mac-toolchain setup] $*"
}

TOOLCHAIN_PATH=$(cd "$(dirname "$0")"; pwd -P)
TARGET="armv7-none-linux-androideabi"

# exit if setup files exist already
if [ -f ./$TARGET.json ] && [ -f ./usr/bin/swift ] && [ -f ./usr/bin/swift-build-tool ]; then
    exit 0;
fi

log "creating $TARGET.json"
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
        "-L${TOOLCHAIN_PATH}/ndk-android-21/usr/lib"
    ]
}
EOF

log "setting symlinks to local swift version"
ln -fs `xcrun --find swift` usr/bin/swift
ln -fs `xcrun --find swift-build-tool` usr/bin/swift-build-tool

log "setup complete"
