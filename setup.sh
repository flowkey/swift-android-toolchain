#!/bin/sh
set +e

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
        "-L${TOOLCHAIN_PATH}/ndk-android-21/usr/lib"
    ]
}
EOF


ln -fs `xcrun --find swift` usr/bin/swift
ln -fs `xcrun --find swift-build-tool` usr/bin/swift-build-tool

echo "Setup complete. Now just add $TOOLCHAIN_PATH to your \$PATH!"
