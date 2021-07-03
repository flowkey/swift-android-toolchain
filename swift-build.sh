#!/bin/bash

set -e

if [[ ! ${ANDROID_ABI} ]]
then
    echo "Please define ANDROID_ABI"
    exit 1
fi

ANDROID_NDK_PATH=/usr/local/ndk/21.4.7075529
if [[ ! `cat "$ANDROID_NDK_PATH/CHANGELOG.md"` ]]; then
    echo "missing ndk in /usr/local/ndk/21.4.7075529"
    exit 1
fi

configure() {
    echo "Configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"

    cmake \
        -G Ninja \
        -DANDROID_ABI=${ANDROID_ABI} \
        -DANDROID_PLATFORM=android-21 \
        -DANDROID_NDK="${ANDROID_NDK_PATH}" \
        -DSWIFT_SDK="$SWIFT_ANDROID_TOOLCHAIN_PATH" \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -C "${SCRIPT_ROOT}/cmake_caches.cmake" \
        -DCMAKE_Swift_COMPILER="$SWIFT_ANDROID_TOOLCHAIN_PATH/usr/bin/swiftc-${ABI_SPECIFIC_POST_FIX}" \
        -DCMAKE_Swift_COMPILER_FORCED=TRUE \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
        -S ${PROJECT_DIRECTORY} \
        -B ${BUILD_DIR}
    
    echo "Finished configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}


build() {
    # reconfigure when build dir does not exist empty
    [[ -d ${BUILD_DIR} ]] || configure

    echo "Compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
    cmake --build ${BUILD_DIR} #--verbose

    $SWIFT_ANDROID_TOOLCHAIN_PATH/usr/bin/copy-libs-${ABI_SPECIFIC_POST_FIX} -output ${LIBRARY_OUTPUT_DIRECTORY}

    echo "Finished compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
readonly SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_ANDROID_TOOLCHAIN_PATH:-$SCRIPT_ROOT/swift-android.xctoolchain}"

ABI_SPECIFIC_POST_FIX=""
case $ANDROID_ABI in
    arm64-v8a)
        ABI_SPECIFIC_POST_FIX="aarch64-linux-android"
        ;;
    armeabi-v7a)
        ABI_SPECIFIC_POST_FIX="arm-linux-androideabi"
        ;;
    x86_64)
        ABI_SPECIFIC_POST_FIX="x86_64-linux-android"
        ;;
esac

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

$SCRIPT_ROOT/setup.sh

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
