#!/bin/bash

set -e

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
source "${SCRIPT_ROOT}/setup.sh"

readonly SCRATCH_PATH="swiftpm-build"
readonly BUILD_TYPE=${BUILD_TYPE:-release}

if [ ${ANDROID_ABI} = "armeabi-v7a" ]; then
    TARGET_TRIPLE="armv7-unknown-linux-androideabi28"
elif [ ${ANDROID_ABI} = "x86_64" ]; then
    TARGET_TRIPLE="x86_64-unknown-linux-android28"
else # assume arm64
    TARGET_TRIPLE="aarch64-unknown-linux-android28"
fi

if [ -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ]
then
    cp -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ${SCRATCH_PATH}/${BUILD_TYPE}.yaml
fi

if [ -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.db ]
then
    cp -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.db ${SCRATCH_PATH}/build.db
fi

function swiftBuild {
    unset ANDROID_NDK_HOME
    swiftly run swift build \
        --swift-sdk ${TARGET_TRIPLE} +${SWIFT_VERSION} \
        --scratch-path ${SCRATCH_PATH} \
        -c ${BUILD_TYPE} \
        -Xcc -fPIC \
        $@
}

swiftBuild $@

# Speed up subsequent incremental builds
cp -f ${SCRATCH_PATH}/${BUILD_TYPE}.yaml ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml
cp -f ${SCRATCH_PATH}/build.db ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.db

if [ "$LIBRARY_OUTPUT_DIRECTORY" ]
then
    copySwiftDependencyLibs
    mkdir -p ${LIBRARY_OUTPUT_DIRECTORY}
    cp -f $(swiftBuild $@ --show-bin-path)/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
fi