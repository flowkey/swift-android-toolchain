#!/usr/bin/env bash

set -e

ORIGINAL_PWD=$PWD
SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
AZURE_BASE_PATH=https://dev.azure.com/compnerd/windows-swift
PATH_TO_SWIFT_TOOLCHAIN="$SCRIPT_ROOT/swift-flowkey.xctoolchain"

SDK_BUILD_ID=9705
TOOLCHAIN_BUILD_ID=9963
ICU_BUILD_ID=9995

log() {
    echo "[swift-android-toolchain] $*"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch ..."
    git -C $SCRIPT_ROOT clean -xdf
fi

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

downloadToolchain() {
    if [[ `uname` == 'Darwin' ]]; then
        BUILD_DEFINITIONS=15
    elif [[ `uname` == 'Linux' ]]; then
        BUILD_DEFINITIONS=14
        TOOLCHAIN_BUILD_ID=9753
    else
        log "unsupported architecture"
        exit 1
    fi

    TOOLCHAIN_BUILD_ID="${TOOLCHAIN_BUILD_ID:-`curl -s "$AZURE_BASE_PATH/_apis/build/builds?definitions=$BUILD_DEFINITIONS"'&resultFilter=succeeded&$top=1&api-version-string=5.0' | jq ".value[0].id"`}"
    TOOLCHAIN_ARTIFACT_URL=`curl -s "$AZURE_BASE_PATH/_apis/build/builds/$TOOLCHAIN_BUILD_ID/artifacts?apiversion-string=2.0" | jq -r ".value[0].resource.downloadUrl"`

    rm -rf $PATH_TO_SWIFT_TOOLCHAIN

    log "Downloading custom Swift Toolchain ($TOOLCHAIN_BUILD_ID) ..."

    curl -OJ `toCachedUrl $TOOLCHAIN_ARTIFACT_URL`
    log "Finished downloading Toolchain"
    unzip -qq 'toolchain.zip'

    log "Setting up custom Swift Toolchain ..."
    mv $SCRIPT_ROOT/temp/toolchain/Developer/Toolchains/*.xctoolchain $PATH_TO_SWIFT_TOOLCHAIN
    chmod -R +x $PATH_TO_SWIFT_TOOLCHAIN/usr/bin
}

toCachedUrl() {
    # download speed on dev.azure.com is super slow, download from our cache for faster downloads
    echo -n $1 #| sed -e s~https://dev.azure.com~http://swift-ci.flowkey.com~g
}

downloadAndroidSdks() {
    SDK_BUILD_ID="${SDK_BUILD_ID:-`curl -s "$AZURE_BASE_PATH"'/_apis/build/builds?definitions=4&resultFilter=succeeded&$top=1&api-version-string=5.0' | jq ".value[0].id"`}"
    SDK_ARTIFACT_URLS=`curl -s "$AZURE_BASE_PATH/_apis/build/builds/$SDK_BUILD_ID/artifacts?apiversion-string=2.0" | jq ".value" | jq "map_values(.resource.downloadUrl)"`

    log "Downloading Android SDKs ($SDK_BUILD_ID) ..."
    for URL in $(echo $SDK_ARTIFACT_URLS | jq -r ".[]"); do
        curl -OJs `toCachedUrl $URL` &
    done
    wait

    unzip -qq 'sdk-android-*.zip'

    rm -rf $SCRIPT_ROOT/Android.sdk-*/
    mv $SCRIPT_ROOT/temp/sdk-android-arm/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-armeabi-v7a
    mv $SCRIPT_ROOT/temp/sdk-android-arm64/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-arm64-v8a
    mv $SCRIPT_ROOT/temp/sdk-android-x64/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-x86_64

    log "Downloading SDKs finished"
}

downloadLibs() {
    ICU_BUILD_ID="${ICU_BUILD_ID:-`curl -s "$AZURE_BASE_PATH"'/_apis/build/builds?definitions=9&resultFilter=succeeded&api-version-string=5.0' | jq ".value[0].id"`}"
    ICU_ARTIFACTS=`curl -s "$AZURE_BASE_PATH/_apis/build/builds/$ICU_BUILD_ID/artifacts?apiversion-string=2.0" | jq ".value" | jq "map_values(.resource.downloadUrl)"`

    log "Downloading ICU ($ICU_BUILD_ID) ..."
    for URL in $(echo $ICU_ARTIFACTS | jq -r ".[]"); do
        # download ICU for android only
        if [[ $URL == *android* ]]; then
            curl -OJs `toCachedUrl $URL` &
        fi
    done
    wait

    unzip -qq 'icu-android-*.zip'

    mv $SCRIPT_ROOT/temp/icu-android-arm/icu-64/usr/lib/*.so $SCRIPT_ROOT/libs/armeabi-v7a
    mv $SCRIPT_ROOT/temp/icu-android-arm64/icu-64/usr/lib/*.so $SCRIPT_ROOT/libs/arm64-v8a
    mv $SCRIPT_ROOT/temp/icu-android-x64/icu-64/usr/lib/*.so $SCRIPT_ROOT/libs/x86_64
}

setup() {
    # fix ndk paths of downloaded android sdks
    sed -i -e s~C:/Microsoft/AndroidNDK64/android-ndk-r16b~${ANDROID_NDK_PATH}~g $SCRIPT_ROOT/Android.sdk-*/usr/lib/swift/android/*/glibc.modulemap

    HOST_SWIFT_BIN_PATH="$PATH_TO_SWIFT_TOOLCHAIN/usr/bin"
    if [ ! -f "$HOST_SWIFT_BIN_PATH/swiftc" ]; then
        log "Couldn't find swift in ${HOST_SWIFT_BIN_PATH}"
        exit 1
    fi

    for arch in armeabi-v7a arm64-v8a x86_64
    do
        ANDROID_SDK="${SCRIPT_ROOT}/Android.sdk-$arch"
        TOOLCHAIN_BIN_DIR="${ANDROID_SDK}/usr/bin"
        mkdir -p "${TOOLCHAIN_BIN_DIR}"
        ln -fs "$HOST_SWIFT_BIN_PATH"/swift* "${TOOLCHAIN_BIN_DIR}"

        # Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
        # This allows it to find the Android swift stdlib in ${SCRIPT_ROOT}/usr/lib/swift/android
        ln -f "$HOST_SWIFT_BIN_PATH/swift" "${TOOLCHAIN_BIN_DIR}/swiftc"
    done

    log "Setup finished"
}

if [[ ! -d $PATH_TO_SWIFT_TOOLCHAIN ]]; then
    downloadToolchain
fi

if [[ ! -d $SCRIPT_ROOT/Android.sdk-armeabi-v7a ]]; then
    downloadAndroidSdks
fi

if [[ ! -f $SCRIPT_ROOT/libs/armeabi-v7a/libicuuc64.so ]]; then
    downloadLibs
fi

setup

cd $ORIGINAL_PWD
rm -rf $SCRIPT_ROOT/temp
