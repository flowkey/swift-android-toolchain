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
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-5.8.1-RELEASE.xctoolchain}"

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

readonly SDK_DIRNAME=swift-android
readonly SWIFT_SDK_PATH="${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}"
readonly HOST=darwin-x86_64 # TODO: add more platforms

copySwiftDependencyLibs() {
    function copyLib {
        local DESTINATION="${LIBRARY_OUTPUT_DIRECTORY}/`basename "$1"`"
        if [ "$1" -nt "${DESTINATION}" ]
        then
            mkdir -p "${LIBRARY_OUTPUT_DIRECTORY}"
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
    echo "Please install the swift-5.8.1-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    echo "On Mac: https://download.swift.org/swift-5.8.1-release/xcode/swift-5.8.1-RELEASE/swift-5.8.1-RELEASE-osx.pkg"
    exit 1
fi

if [[ ! -f "${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract" ]];
then
    echo "Missing symlink '${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract'."
    echo "We need 'sudo' permission to create it (just this once)."
    sudo ln -s swift ${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract || exit 1
fi

downloadSdks() {
    [ ! -d ${SDK_DIR} ] && mkdir -p ${SDK_DIR}
    pushd ${SDK_DIR} > /dev/null
    
    local ORIGINAL_FILENAME="swift-5.8-android-24-sdk"

    if [ ! -f "${ORIGINAL_FILENAME}.tar.xz" ]
    then
        log "Downloading ${SDK_DIRNAME} SDK..."
        local SDK_URL_BASEPATH="https://github.com/buttaface/swift-android-sdk/releases/download/5.8"
        curl -LO ${SDK_URL_BASEPATH}/${ORIGINAL_FILENAME}.tar.xz
    fi
    
    if [ ! -d "${SDK_DIRNAME}" ]
    then
        log "Extracting ${SDK_DIRNAME} SDK..."
        tar --extract --file ${ORIGINAL_FILENAME}.tar.xz
        # rm ${ORIGINAL_FILENAME}.tar.xz
        mv ${ORIGINAL_FILENAME} ${SDK_DIRNAME}
    fi

    popd > /dev/null
}

downloadSdks

# dynamic resources
if [ ! -f "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift/clang" ]
then
    ln -fs \
        ${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/lib64/clang/14.0.6 \
        ${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift/clang
fi

# static resources
if [ ! -f "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift_static/clang" ]
then
    ln -fs \
        ${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/lib64/clang/14.0.6 \
        ${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift_static/clang
fi
