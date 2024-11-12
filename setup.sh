log() {
    echo "[swift-android-toolchain] $*"
}

readonly SWIFT_VERSION="6.0.2"
readonly TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/Library/Developer/Toolchains/swift-${SWIFT_VERSION}-RELEASE.xctoolchain}"
if [ ! -d ${TOOLCHAIN_PATH} ]
then
    log "Please install the swift-${SWIFT_VERSION}-RELEASE toolchain (or set TOOLCHAIN_PATH)"
    log "On Mac: https://download.swift.org/swift-${SWIFT_VERSION}-release/xcode/swift-${SWIFT_VERSION}-RELEASE/swift-6.0.2-RELEASE-osx.pkg"

    exit 1
fi

readonly SWIFT_ANDROID_SDK="swift-${SWIFT_VERSION}-RELEASE-android-24-0.1"
readonly SWIFT_ANDROID_SDK_CHECKSUM="d75615eac3e614131133c7cc2076b0b8fb4327d89dce802c25cd53e75e1881f4"
if [ ! $(swift sdk list | grep ${SWIFT_ANDROID_SDK}) ]
then
    swift sdk install \
        https://github.com/finagolfin/swift-android-sdk/releases/download/${SWIFT_VERSION}/${SWIFT_ANDROID_SDK}.artifactbundle.tar.gz \
        --checksum ${SWIFT_ANDROID_SDK_CHECKSUM}
fi

readonly NDK_VERSION="27.1.12297006"
readonly ANDROID_NDK_PATH="${ANDROID_NDK_PATH:-/usr/local/ndk/${NDK_VERSION}}"
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    log "no ndk found under ANDROID_NDK_PATH=${ANDROID_NDK_PATH}"
    log "download ndk ${NDK_VERSION} and create a symlink in '/usr/local/ndk/${NDK_VERSION}' pointing to it"
    exit 1
fi

if [[ ! ${ANDROID_ABI} ]]
then
    log "ANDROID_ABI not set. Defaulting to 'arm64-v8a'"
    ANDROID_ABI=arm64-v8a
fi

for LAST_ARGUMENT in $@; do :; done
readonly PROJECT_DIRECTORY=${LAST_ARGUMENT:-$PWD}
readonly BUILD_DIR="${PROJECT_DIRECTORY}/build/${ANDROID_ABI}"
readonly LIBRARY_OUTPUT_DIRECTORY="${LIBRARY_OUTPUT_DIRECTORY:-${PROJECT_DIRECTORY}/libs/${ANDROID_ABI}}"
readonly CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

readonly SWIFT_SDK_PATH="${HOME}/Library/org.swift.swiftpm/swift-sdks/${SWIFT_ANDROID_SDK}.artifactbundle/swift-${SWIFT_VERSION}-release-android-24-sdk/android-27c-sysroot"

copySwiftDependencyLibs() {
    log "Copying Swift dependencies..."
    function copyLib {
        local DESTINATION="${LIBRARY_OUTPUT_DIRECTORY}/`basename "$1"`"
        # log "${DESTINATION}"
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
    # Check if EXCLUDED_LIBS is set; if not, initialize it as an empty array.
    EXCLUDED_LIBS="${EXCLUDED_LIBS:-}"

    # Append libc++.so to EXCLUDED_LIBS if it’s not already included.
    if [[ ! " ${EXCLUDED_LIBS[@]} " =~ "libc++.so" ]]; then
        EXCLUDED_LIBS+=" libc++.so"
    fi

    if [ ${#EXCLUDED_LIBS} != "0" ]
    then
        local EXCLUSIONS_STRING=`for EXCLUSION in ${EXCLUDED_LIBS}; do printf %s "-e ${EXCLUSION} "; done`
        LIB_FILES=$(grep --invert-match ${EXCLUSIONS_STRING} <<< "$LIB_FILES")
    fi

    for FILE_PATH in ${LIB_FILES[@]}
    do
        copyLib "${FILE_PATH}"
    done
}
