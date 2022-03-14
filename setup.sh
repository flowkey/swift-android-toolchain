#!/usr/bin/env bash

set -e

readonly SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
readonly SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_ANDROID_TOOLCHAIN_PATH:-$SCRIPT_ROOT/swift-android.xctoolchain}"

log() {
    echo "[swift-android-toolchain] $*"
}

clean() {
    rm -rf $SCRIPT_ROOT/temp $SCRIPT_ROOT/swift-android.xctoolchain
}

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

downloadToolchain() {
    mkdir -p $SCRIPT_ROOT/temp
    cd $SCRIPT_ROOT/temp

    log "Downloading Toolchain..."

    # mirror of https://github.com/vgorloff/swift-everywhere-toolchain/releases/tag/1.0.78
    TOOLCHAIN_PATH="https://swift-toolchain-artifacts.flowkeycdn.com/swift-android-5.5.2.tar.gz"

    curl -LO $TOOLCHAIN_PATH
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

if [[ ! -d $SWIFT_ANDROID_TOOLCHAIN_PATH ]]; then
    clean
    downloadToolchain
fi

setup

rm -rf $SCRIPT_ROOT/temp
