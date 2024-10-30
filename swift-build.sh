#!/bin/bash

set -e

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
source "${SCRIPT_ROOT}/setup.sh"

if [ ! -d ${TOOLCHAIN_PATH} ]
then
    echo "Please install the swift-6.0.1-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    echo "On Mac: https://download.swift.org/swift-6.0.1-release/xcode/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-osx.pkg"
    exit 1
fi

configure() {
    echo "Configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
    echo "SDK: ${SWIFT_SDK_PATH}"

    cmake \
        -G Ninja \
        -DANDROID_ABI=${ANDROID_ABI} \
        -DANDROID_PLATFORM=android-24 \
        -DANDROID_NDK="${ANDROID_NDK_PATH}" \
        -DSWIFT_SDK="${SWIFT_SDK_PATH}" \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -C "${SCRIPT_ROOT}/cmake_caches.cmake" \
        -DCMAKE_Swift_COMPILER="${TOOLCHAIN_PATH}/usr/bin/swiftc" \
        -DCMAKE_Swift_COMPILER_FORCED=TRUE \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
        -S ${PROJECT_DIRECTORY} \
        -B ${BUILD_DIR}
    
    echo "Finished configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

build() {
    echo "Building ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"

    # reconfigure when build dir does not exist
    [[ -d ${BUILD_DIR} ]] || configure

    echo "Compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
    cmake --build ${BUILD_DIR} #--verbose
    echo finished build ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}

    copySwiftDependencyLibs

    echo "Finished compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
}

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
