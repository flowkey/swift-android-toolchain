#!/bin/bash

set -e

if [[ ! ${ANDROID_NDK_PATH} ]]
then
    echo "Please define ANDROID_NDK_PATH"
    exit 1
fi

if [[ ! ${ANDROID_ABI} ]]
then
    echo "Please define ANDROID_ABI"
    exit 1
fi

# Add `ld.gold` to PATH
# This is weird because it looks like it's the armv7a ld.gold but it seems to support all archs
LOWERCASE_UNAME=`uname | tr '[:upper:]' '[:lower:]'`
PATH="${ANDROID_NDK_PATH}/toolchains/arm-linux-androideabi-4.9/prebuilt/${LOWERCASE_UNAME}-x86_64/arm-linux-androideabi/bin:$PATH"

configure() {
    echo "Configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
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
    
    echo "Finished configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

build() {
    # reconfigure when build dir is empty
    # ls ${BUILD_DIR}/* > /dev/null 2>&1 || configure

    echo "Compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
    cmake --build . #--verbose

    # Install stdlib etc. into output directory
    cp "${ANDROID_SDK}/usr/lib/swift/android"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "${SWIFT_ANDROID_TOOLCHAIN_PATH}/libs/${ANDROID_ABI}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "${ANDROID_NDK_PATH}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so" "${LIBRARY_OUTPUT_DIRECTORY}"

    echo "Finished compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
readonly SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_ANDROID_TOOLCHAIN_PATH:-$SCRIPT_ROOT}"

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"

# You need a different SDK per arch, e.g. swift-android-toolchain/Android.sdk-armeabi-v7a/
readonly ANDROID_SDK="$SWIFT_ANDROID_TOOLCHAIN_PATH/Android.sdk-${ANDROID_ABI}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

mkdir -p $BUILD_DIR
cd $BUILD_DIR

for arg in "$@"
do
    case $arg in
        -c|--configure)
            configure
            exit 0
        ;;
    esac
done

build
