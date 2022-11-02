#!/usr/bin/env bash

set -e

readonly SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
readonly SDK_DIR="${SCRIPT_ROOT}/sdk"
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-5.7-RELEASE.xctoolchain}"

log() {
    echo "[swift-android-toolchain] $*"
}

clean() {
    rm -rf ${SDK_DIR}
}

downloadSdks() {
    mkdir -p ${SDK_DIR}
    cd ${SDK_DIR}

    for SDK in aarch64 armv7 x86_64
    do
        local SDK_DIRNAME=${SDK};
        [ ${SDK} = "aarch64" ] && SDK_DIRNAME=arm64-v8a
        [ ${SDK} = "armv7" ] && SDK_DIRNAME=armeabi-v7a

        local ORIGINAL_FILENAME="swift-5.7-android-${SDK}-24-sdk"

        if [ ! -f "${ORIGINAL_FILENAME}.tar.xz" ]
        then
            log "Downloading ${SDK_DIRNAME} SDK..."
            local SDK_URL_BASEPATH="https://github.com/buttaface/swift-android-sdk/releases/download/5.7"
            curl -LO ${SDK_URL_BASEPATH}/${ORIGINAL_FILENAME}.tar.xz
        fi
        
        if [ ! -d "${SDK_DIRNAME}" ]
        then
            log "Extracting ${SDK_DIRNAME} SDK..."
            tar --extract --file ${ORIGINAL_FILENAME}.tar.xz
            # rm ${ORIGINAL_FILENAME}.tar.xz
            mv ${ORIGINAL_FILENAME} ${SDK_DIRNAME}
        fi
    done

    log "Done!"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch..."
    clean
fi

if [ ! -d ${TOOLCHAIN_PATH} ]
then
    echo "Please install the swift-5.7-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    echo "On Mac: https://download.swift.org/swift-5.7-release/xcode/swift-5.7-RELEASE/swift-5.7-RELEASE-osx.pkg"
    exit 1
fi

if [[ ! -f "${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract" ]];
then
    echo "Missing symlink '${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract'."
    echo "We need 'sudo' permission to create it (just this once)."
    sudo ln -s swift ${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract || exit 1
fi

downloadSdks
