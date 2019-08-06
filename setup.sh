#!/bin/bash

set -e

ORIGINAL_PWD=$PWD
SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
AZURE_BASE_PATH=https://dev.azure.com/compnerd/windows-swift

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

PATH_TO_SWIFT_TOOLCHAIN="$SCRIPT_ROOT/swift-flowkey.xctoolchain"

log() {
    echo "[swift-android-toolchain] $*"
}

downloadToolchain() {
    if [[ `uname` == 'Darwin' ]]; then
         definitions=15
    elif [[ `uname` == 'Linux' ]]; then
        definitions=14
    fi

    TOOLCHAIN_BUILD_ID=`curl -s "$AZURE_BASE_PATH/_apis/build/builds?definitions=$definitions&resultFilter=succeeded&api-version-string=5.0" | jq ".value[0].id"`
    TOOLCHAIN_ARTIFACT=`curl -s "$AZURE_BASE_PATH/_apis/build/builds/$TOOLCHAIN_BUILD_ID/artifacts?apiversion-string=2.0" | jq -r ".value[0].resource.downloadUrl"`

    rm -rf $PATH_TO_SWIFT_TOOLCHAIN

    log "Downloading custom Swift Toolchain ($TOOLCHAIN_BUILD_ID) ..."
    curl -OJ $TOOLCHAIN_ARTIFACT
    log "Finished downloading Toolchain"
    unzip -qq 'toolchain.zip'

    log "Moving new toolchain to $PATH_TO_SWIFT_TOOLCHAIN"
    mv $SCRIPT_ROOT/temp/toolchain/Developer/Toolchains/*.xctoolchain $PATH_TO_SWIFT_TOOLCHAIN

    log "done"
}

downloadAndroidSdks() {
    SDK_BUILD_ID=`curl -s "$AZURE_BASE_PATH/_apis/build/builds?definitions=4&resultFilter=succeeded&api-version-string=5.0" | jq ".value[0].id"`
    SDK_ARTIFACTS=`curl -s "$AZURE_BASE_PATH/_apis/build/builds/$SDK_BUILD_ID/artifacts?apiversion-string=2.0" | jq ".value" | jq "map_values(.resource.downloadUrl)"`

    log "Downloading Android SDKs ($SDK_BUILD_ID) ..."
    for URL in $(echo $SDK_ARTIFACTS | jq -r ".[]"); do
        curl -OJs $URL &
    done
    wait

    unzip -qq 'sdk-android-*.zip'

    rm -rf $SCRIPT_ROOT/Android.sdk-*/
    mv $SCRIPT_ROOT/temp/sdk-android-arm/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-armeabi-v7a
    mv $SCRIPT_ROOT/temp/sdk-android-arm64/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-arm64-v8a
    mv $SCRIPT_ROOT/temp/sdk-android-x64/Developer/Platforms/Android.platform/Developer/SDKs/Android.sdk/ $SCRIPT_ROOT/Android.sdk-x86_64

    log "Downloading SDKs finished"
}

setup() {
    # fix paths to ndk in downloaded android sdks
    sed -i "" -e s~C:/Microsoft/AndroidNDK64/android-ndk-r16b~${ANDROID_NDK_PATH}~g $SCRIPT_ROOT/Android.sdk-*/usr/lib/swift/android/*/glibc.modulemap

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
        chmod a+x "${TOOLCHAIN_BIN_DIR}/swiftc"
    done

    log "Setup finished"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch ..." 
    rm -rf $PATH_TO_SWIFT_TOOLCHAIN
    rm -rf $SCRIPT_ROOT/Android.sdk-*
fi

if [ ! -d $PATH_TO_SWIFT_TOOLCHAIN ]; then
    downloadToolchain
fi

if [ ! -d $SCRIPT_ROOT/Android.sdk-armeabi-v7a ]; then    
    downloadAndroidSdks
fi

setup

cd $ORIGINAL_PWD
rm -rf $SCRIPT_ROOT/temp
