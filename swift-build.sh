#!/bin/bash

set -e

PROJECT_DIRECTORY=${1:-$PWD}
echo "building $PROJECT_DIRECTORY"

SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_ANDROID_TOOLCHAIN_PATH:-$SCRIPT_ROOT}"
LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"

if [[ ! ${ANDROID_NDK_PATH} ]]
then
    echo "Please define ANDROID_NDK_PATH"
    exit 1
fi

# Add `ld.gold` to PATH
# This is weird because it looks like it's the armv7a ld.gold but it seems to support all archs
LOWERCASE_UNAME=`uname | tr '[:upper:]' '[:lower:]'`
PATH="${ANDROID_NDK_PATH}/toolchains/arm-linux-androideabi-4.9/prebuilt/${LOWERCASE_UNAME}-x86_64/arm-linux-androideabi/bin:$PATH"

build() {
    CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}
    echo "Compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"

    BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
    # rm -rf $BUILD_DIR
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    # You need a different SDK per arch, e.g. swift-android-toolchain/Android.sdk-armeabi-v7a/
    export ANDROID_SDK="$SWIFT_ANDROID_TOOLCHAIN_PATH/Android.sdk-${ANDROID_ABI}"

    $SWIFT_ANDROID_TOOLCHAIN_PATH/setup.sh

    cmake \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
        -DANDROID_ABI=${ANDROID_ABI} \
        -DANDROID_PLATFORM=android-21 \
        -DANDROID_NDK="${ANDROID_NDK_PATH}" \
        -DSWIFT_SDK="${ANDROID_SDK}" \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -C "${SWIFT_ANDROID_TOOLCHAIN_PATH}/cmake_caches.cmake" \
        -DCMAKE_Swift_COMPILER="${ANDROID_SDK}/usr/bin/swiftc" \
        -DCMAKE_Swift_COMPILER_FORCED=TRUE \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} \
        ${PROJECT_DIRECTORY}

    cmake --build . #--verbose

    # Install stdlib etc. into output directory
    cp "${ANDROID_SDK}/usr/lib/swift/android"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "${SWIFT_ANDROID_TOOLCHAIN_PATH}/libs/${ANDROID_ABI}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "${ANDROID_NDK_PATH}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so" "${LIBRARY_OUTPUT_DIRECTORY}"

    echo "Finished compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

build
