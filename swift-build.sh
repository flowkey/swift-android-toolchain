#!/bin/bash

set -e

ANDROID_NDK_PATH=/usr/local/ndk/25.1.8937393
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    echo "no ndk found under /usr/local/ndk/25.1.8937393"
    echo "download ndk 25.1.8937393 and create a symlink in '/usr/local/ndk/25.1.8937393' pointing to it"
    exit 1
fi

if [[ ! ${ANDROID_ABI} ]]
then
    echo "Please define ANDROID_ABI"
    exit 1
fi

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-5.7-RELEASE.xctoolchain}"

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

readonly SWIFT_SDK_PATH="${SCRIPT_ROOT}/sdk/${ANDROID_ABI}"

if [ ! -d ${TOOLCHAIN_PATH} ]
then
    echo "Please install the swift-5.7-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    echo "On Mac: https://download.swift.org/swift-5.7-release/xcode/swift-5.7-RELEASE/swift-5.7-RELEASE-osx.pkg"
    exit 1
fi

configure() {
    echo "Configure ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"

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
    # reconfigure when build dir does not exist
    [[ -d ${BUILD_DIR} ]] || configure

    echo "Compiling ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}"
    cmake --build ${BUILD_DIR} #--verbose
    echo finished build ${CMAKE_BUILD_TYPE} for ${ANDROID_ABI}

    function copyLib {
        local DESTINATION="${LIBRARY_OUTPUT_DIRECTORY}/`basename "$1"`"
        if [ "$1" -nt "${DESTINATION}" ]; then cp -f "$1" "${DESTINATION}"; fi
    }

    for FILE_PATH in `find "${SWIFT_SDK_PATH}/usr/lib" -type f -iname *.so -print`
    do
        copyLib "${FILE_PATH}"
    done

    copyLib "${ANDROID_NDK_PATH}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so"

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

${SCRIPT_ROOT}/setup.sh
build
