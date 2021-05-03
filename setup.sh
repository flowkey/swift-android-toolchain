#!/usr/bin/env bash

set -e

SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
PATH_TO_SWIFT_TOOLCHAIN="$SCRIPT_ROOT/swift-android.xctoolchain"
UNAME=`uname`

log() {
    echo "[swift-android-toolchain] $*"
}

if [[ ! ${ANDROID_NDK_PATH} ]] || [[ ! `cat "$ANDROID_NDK_PATH/changelog.md" | grep "r21b"` ]]; then
    log "Please define ANDROID_NDK_PATH and point to your local version of r21b"
    exit 1
fi

clean() {
    git -C $SCRIPT_ROOT clean -xdf
}

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

downloadToolchain() {
    mkdir -p $SCRIPT_ROOT/temp
    cd $SCRIPT_ROOT/temp

    log "Downloading Toolchain..."
    curl -LO https://github.com/vgorloff/swift-everywhere-toolchain/releases/download/1.0.66/swift-android-toolchain.tar.gz
    log "Extracting Toolchain..."
    tar -xzf $SCRIPT_ROOT/temp/*.tar.gz
    mv $SCRIPT_ROOT/temp/swift-android-toolchain $SCRIPT_ROOT/swift-android.xctoolchain
}

setup() {
    rm -rf $SCRIPT_ROOT/temp/
    log "Setup finished"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch ..."
    clean
fi

if [[ ! -d $PATH_TO_SWIFT_TOOLCHAIN ]] || [[ ! -d $SCRIPT_ROOT/swift-android.xctoolchain ]]; then
    clean
    downloadToolchain
fi

setup

rm -rf $SCRIPT_ROOT/temp
