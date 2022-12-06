#!/usr/bin/env bash

set -e

ANDROID_NDK_PATH=/usr/local/ndk/25.1.8937393
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    echo "no ndk found under /usr/local/ndk/25.1.8937393"
    echo "download ndk 25.1.8937393 and create a symlink in '/usr/local/ndk/25.1.8937393' pointing to it"
    exit 1
fi

if [[ ! ${ANDROID_ABI} ]]
then
    echo "ANDROID_ABI not set. Defaulting to 'arm64-v8a'"
    ANDROID_ABI=arm64-v8a
fi

readonly SDK_DIR="${SCRIPT_ROOT}/sdk"
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-5.7-RELEASE.xctoolchain}"

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

readonly SWIFT_SDK_PATH="${SCRIPT_ROOT}/sdk/${ANDROID_ABI}"
readonly HOST=darwin-x86_64 # TODO: add more platforms

copyLibs() {
    function copyLib {
        local DESTINATION="${LIBRARY_OUTPUT_DIRECTORY}/`basename "$1"`"
        if [ true || "$1" -nt "${DESTINATION}" ]
        then
            cp -f "$1" "${DESTINATION}"
        fi
    }

    local LIB_FILES=`find "${SWIFT_SDK_PATH}/usr/lib" -type f -iname "*.so" -print`

    # EXCLUDED_LIBS are optionally provided to script, e.g. from Gradle:
    if [ ${#EXCLUDED_LIBS} != "0" ]
    then
        local EXCLUSIONS_STRING=`for EXCLUSION in ${EXCLUDED_LIBS}; do printf %s "-e ${EXCLUSION} "; done`
        LIB_FILES=$(grep --invert-match ${EXCLUSIONS_STRING} <<< "$LIB_FILES")
    fi

    for FILE_PATH in ${LIB_FILES[@]}
    do
        copyLib "${FILE_PATH}"
    done

    copyLib "${ANDROID_NDK_PATH}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so"
}

log() {
    echo "[swift-android-toolchain] $*"
}

clean() {
    rm -rf ${SDK_DIR}
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch..."
    clean
fi

if [ ! -d ${TOOLCHAIN_PATH} ]
then
    echo "Please install the swift-5.7-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    echo "On Mac: https://download.swift.org/swift-5.7-release/xcode/swift-5.7-RELEASE/swift-5.7-RELEASE-osx.pkg"
    exit 1
fi

if [[ ! -f "${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract" ]];
then
    echo "Missing symlink '${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract'."
    echo "We need 'sudo' permission to create it (just this once)."
    sudo ln -s swift ${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract || exit 1
fi

downloadSdks() {
    mkdir -p ${SDK_DIR}
    pushd ${SDK_DIR} > /dev/null

    for SDK in aarch64 armv7 x86_64
    do
        local SDK_DIRNAME=${SDK};
        [ ${SDK} = "aarch64" ] && SDK_DIRNAME=arm64-v8a
        [ ${SDK} = "armv7" ] && SDK_DIRNAME=armeabi-v7a

        local ORIGINAL_FILENAME="swift-5.7-android-${SDK}-24-sdk"

        if [ ! -f "${ORIGINAL_FILENAME}.tar.xz" ]
        then
            log "Downloading ${SDK_DIRNAME} SDK..."
            local SDK_URL_BASEPATH="https://github.com/buttaface/swift-android-sdk/releases/download/5.7"
            curl -LO ${SDK_URL_BASEPATH}/${ORIGINAL_FILENAME}.tar.xz
        fi
        
        if [ ! -d "${SDK_DIRNAME}" ]
        then
            log "Extracting ${SDK_DIRNAME} SDK..."
            tar --extract --file ${ORIGINAL_FILENAME}.tar.xz
            # rm ${ORIGINAL_FILENAME}.tar.xz
            mv ${ORIGINAL_FILENAME} ${SDK_DIRNAME}
        fi
    done

    popd > /dev/null
}

downloadSdks

readonly DESTINATION_FILE="${SCRIPT_ROOT}/${ANDROID_ABI}.json"

if [ ! -f "${DESTINATION_FILE}" ]; then
if [ ${ANDROID_ABI} = "armeabi-v7a" ]; then
    cat <<- EOF > "${DESTINATION_FILE}"
    {
        "version": 1,
        "target": "armv7-unknown-linux-androideabi24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin",
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
elif [ ${ANDROID_ABI} = "x86_64" ]; then
    cat <<- EOF > "${DESTINATION_FILE}"
    {
        "version": 1,
        "target": "x86_64-unknown-linux-android24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin",
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
else # assume arm64
    cat <<- EOF > "${DESTINATION_FILE}"
    {
        "version": 1,
        "target": "aarch64-unknown-linux-android24",
        "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
        "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
        "extra-cc-flags": ["-fPIC"],
        "extra-swiftc-flags": [
            "-resource-dir",
            "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift",
            "-tools-directory",
            "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin"
        ],
        "extra-cpp-flags": ["-lstdc++"]
    }
EOF
fi
fi