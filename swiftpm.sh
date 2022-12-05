#!/bin/bash

set -e

ANDROID_NDK_PATH=/usr/local/ndk/25.1.8937393
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    echo "no ndk found under /usr/local/ndk/25.1.8937393"
    echo "download ndk 25.1.8937393 and create a symlink in '/usr/local/ndk/25.1.8937393' pointing to it"
    exit 1
fi

if [ ! ${ANDROID_ABI} ]
then
    ANDROID_ABI="arm64-v8a"
fi

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-5.7-RELEASE.xctoolchain}"

TMPFILE=$(mktemp)
HOST=darwin-x86_64

if [ ${ANDROID_ABI} = "armeabi-v7a" ]
then
    cat <<- EOF > ${TMPFILE}
    {
        "version": 1,
        "target": "armv7-unknown-linux-androideabi24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin",
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
elif [ ${ANDROID_ABI} = "x86_64" ]
then
    cat <<- EOF > ${TMPFILE}
    {
        "version": 1,
        "target": "x86_64-unknown-linux-android24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin",
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
else # assume arm64
    cat <<- EOF > ${TMPFILE}
    {
        "version": 1,
        "target": "aarch64-unknown-linux-android24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin"
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
fi

ln -fs \
    ${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/lib64/clang/14.0.6 \
    ${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift/clang

${TOOLCHAIN_PATH}/usr/bin/swift build --destination "${TMPFILE}" $@

if [ "$LIBRARY_OUTPUT_DIRECTORY" ]
then
    BIN_PATH=$(${TOOLCHAIN_PATH}/usr/bin/swift build --destination "${TMPFILE}" --show-bin-path $@)
    mkdir -p ${LIBRARY_OUTPUT_DIRECTORY}
    cp -f "${BIN_PATH}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
fi