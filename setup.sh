ANDROID_NDK_PATH="${ANDROID_NDK_PATH:-/usr/local/ndk/27.1.12297006}"
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    log "no ndk found under ANDROID_NDK_PATH=${ANDROID_NDK_PATH}"
    log "download ndk 27.1.12297006 and create a symlink in '/usr/local/ndk/27.1.12297006' pointing to it"
    exit 1
fi

if [[ ! ${ANDROID_ABI} ]]
then
    log "ANDROID_ABI not set. Defaulting to 'arm64-v8a'"
    ANDROID_ABI=arm64-v8a
fi

: "${SCRIPT_ROOT:=$(cd "$(dirname "$0")"; pwd -P)}"

readonly SDK_DIR="${SCRIPT_ROOT}/sdk"
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-6.0.1-RELEASE.xctoolchain}"

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

readonly SWIFT_SDK_PATH="${SCRIPT_ROOT}/sdk/swift-6.0.1-RELEASE-android-24-0.1.artifactbundle/swift-6.0.1-release-android-24-sdk/android-27b-sysroot"

readonly HOST=darwin-x86_64 # TODO: add more platforms

copySwiftDependencyLibs() {
    log "Copying Swift dependencies..."
    function copyLib {
        local DESTINATION="${LIBRARY_OUTPUT_DIRECTORY}/`basename "$1"`"
        log "${DESTINATION}"
        if [ "$1" -nt "${DESTINATION}" ]
        then
            mkdir -p "${LIBRARY_OUTPUT_DIRECTORY}"
            cp -f "$1" "${DESTINATION}"
        fi
    }

    if [ ${ANDROID_ABI} = "armeabi-v7a" ]; then
        TARGET_LIB_DIR="arm-linux-androideabi"
    elif [ ${ANDROID_ABI} = "x86_64" ]; then
        TARGET_LIB_DIR="x86_64-linux-android"
    else
        TARGET_LIB_DIR="aarch64-linux-android"
    fi

    local LIB_FILES=`find "${SWIFT_SDK_PATH}/usr/lib/${TARGET_LIB_DIR}/24" -type f -iname "*.so" -print`

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
    log "Please install the swift-6.0.1-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    log "On Mac: https://download.swift.org/swift-6.0.1-release/xcode/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-osx.pkg"
    
    exit 1
fi

if [[ ! -f "${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract" ]];
then
    log "Missing symlink '${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract'."
    log "We need 'sudo' permission to create it (just this once)."
    sudo ln -s swift ${TOOLCHAIN_PATH}/usr/bin/swift-autolink-extract || exit 1
fi

downloadSdks() {
    [ ! -d ${SDK_DIR} ] && mkdir -p ${SDK_DIR}
    pushd ${SDK_DIR} > /dev/null

    local ORIGINAL_FILENAME="swift-6.0.1-RELEASE-android-24-0.1.artifactbundle.tar.gz"

    if [ ! -f "${ORIGINAL_FILENAME}" ]
    then
        log "Downloading ${SWIFT_SDK_PATH} SDK..."
        local SDK_URL_BASEPATH="https://github.com/finagolfin/swift-android-sdk/releases/download/6.0.1"
        local SDK_DOWNLOAD_URL="${SDK_URL_BASEPATH}/${ORIGINAL_FILENAME}"
        curl -LO ${SDK_DOWNLOAD_URL}
    fi

    if [ ! -d "${SWIFT_SDK_PATH}" ]
    then
        log "Extracting ${SWIFT_SDK_PATH} SDK..."
        tar --extract --file ${ORIGINAL_FILENAME}
    fi

    popd > /dev/null
}

downloadSdks