#!/usr/bin/env bash

set -e

SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
PATH_TO_SWIFT_TOOLCHAIN="/Users/michaelknoch/Downloads/swift-android-toolchain"
UNAME=`uname`

log() {
    echo "[swift-android-toolchain] $*"
}

if [[ ! ${ANDROID_NDK_PATH} ]] || [[ ! `cat "$ANDROID_NDK_PATH/changelog.md" | grep "r16b"` ]]; then
    log "Please define ANDROID_NDK_PATH and point to your local version of ndk-r16b"
    if [[ ${UNAME} == "Darwin" ]]; then
        log "Download from https://dl.google.com/android/repository/android-ndk-r16b-darwin-x86_64.zip"
    elif [[ ${UNAME} == "Linux" ]]; then
        log "Download from https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip"
    fi
    exit 1
fi

clean() {
    git -C $SCRIPT_ROOT clean -xdf
}

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

downloadArtifacts() {
    mkdir -p $SCRIPT_ROOT/temp
    cd $SCRIPT_ROOT/temp

    BASEPATH="https://swift-toolchain-artifacts.flowkeycdn.com"

    if [[ ${UNAME} == "Darwin" ]]; then
        VERSION="20200112.01"
    elif [[ ${UNAME} == "Linux" ]]; then
        VERSION="stable_2"
    fi

    log "Downloading Toolchain Artifacts..."
    curl -JO ${BASEPATH}/${VERSION}/${UNAME}.zip
    log "Extracting Toolchain Artifacts..."
    unzip -qq $SCRIPT_ROOT/temp/${UNAME}.zip
    mv $SCRIPT_ROOT/temp/${UNAME}/* $SCRIPT_ROOT
}

setup() {
    # fix ndk paths of downloaded android sdks
   # sed -i -e s~C:/Microsoft/AndroidNDK64/android-ndk-r16b~${ANDROID_NDK_PATH}~g $SCRIPT_ROOT/Android.sdk-*/usr/lib/swift/android/*/glibc.modulemap

    HOST_SWIFT_BIN_PATH="$PATH_TO_SWIFT_TOOLCHAIN/usr/bin"
    if [ ! -f "$HOST_SWIFT_BIN_PATH/swiftc" ]; then
        log "Couldn't find swift in ${HOST_SWIFT_BIN_PATH}"
        exit 1
    fi

#    for arch in armeabi-v7a arm64-v8a x86_64
#    do
 #       ANDROID_SDK="${SCRIPT_ROOT}/Android.sdk-$arch"
 #       TOOLCHAIN_BIN_DIR="${ANDROID_SDK}/usr/bin"
 #       mkdir -p "${TOOLCHAIN_BIN_DIR}"
 #       ln -fs "$HOST_SWIFT_BIN_PATH"/swift* "${TOOLCHAIN_BIN_DIR}"

        # Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
        # This allows it to find the Android swift stdlib in ${SCRIPT_ROOT}/usr/lib/swift/android
  #      ln -f "$HOST_SWIFT_BIN_PATH/swift" "${TOOLCHAIN_BIN_DIR}/swiftc"
 #   done

    rm -rf $SCRIPT_ROOT/temp/
    log "Setup finished"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch ..."
    clean
fi

#if [[ ! -d $PATH_TO_SWIFT_TOOLCHAIN ]] || [[ ! -d $SCRIPT_ROOT/Android.sdk-armeabi-v7a ]] || [[ ! -f $SCRIPT_ROOT/libs/armeabi-v7a/libicuuc64.so ]]; then
  #  clean
  #  downloadArtifacts
#fi

setup

rm -rf $SCRIPT_ROOT/temp
