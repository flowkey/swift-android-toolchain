log() {
    echo "[swift-android-toolchain] $*"
}

readonly SWIFT_MAJOR_VERSION=6
readonly SWIFT_MINOR_VERSION=3
readonly SWIFT_PATCH_VERSION=2

readonly SWIFT_VERSION="${SWIFT_MAJOR_VERSION}.${SWIFT_MINOR_VERSION}.${SWIFT_PATCH_VERSION}"

readonly SWIFT_ANDROID_SDK="swift-${SWIFT_VERSION}-RELEASE_android"
readonly SWIFT_ANDROID_SDK_CHECKSUM="939e933549d12d28f2e0bf71019d734d309859e9773c572657ce565a81f85d68"

swiftly install "${SWIFT_VERSION}"

readonly NDK_VERSION="27.1.12297006"
readonly ANDROID_NDK_PATH="${ANDROID_NDK_PATH:-/usr/local/ndk/${NDK_VERSION}}"
if [[ ! `cat "${ANDROID_NDK_PATH}/CHANGELOG.md" 2> /dev/null` ]]; then
    log "no ndk found under ANDROID_NDK_PATH=${ANDROID_NDK_PATH}"
    log "download ndk ${NDK_VERSION} and create a symlink in '/usr/local/ndk/${NDK_VERSION}' pointing to it"
    exit 1
fi

readonly SWIFT_SDK_BUNDLE_PATH="${HOME}/Library/org.swift.swiftpm/swift-sdks/${SWIFT_ANDROID_SDK}.artifactbundle"

if [ ! $(swift sdk list | grep ${SWIFT_ANDROID_SDK}) ]
then
    swiftly run swift sdk install \
        https://download.swift.org/swift-${SWIFT_VERSION}-release/android-sdk/swift-${SWIFT_VERSION}-RELEASE/${SWIFT_ANDROID_SDK}.artifactbundle.tar.gz \
        --checksum ${SWIFT_ANDROID_SDK_CHECKSUM}
fi

if [ ! -d "${SWIFT_SDK_BUNDLE_PATH}/swift-android/ndk-sysroot/usr/include" ]
then
    log "Setting up Android NDK sysroot in SDK bundle..."
    ANDROID_NDK_HOME="${ANDROID_NDK_PATH}" "${SWIFT_SDK_BUNDLE_PATH}/swift-android/scripts/setup-android-sdk.sh"
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

readonly SWIFT_SDK_PATH="${HOME}/Library/org.swift.swiftpm/swift-sdks/${SWIFT_ANDROID_SDK}.artifactbundle/swift-android/swift-resources"

copySwiftDependencyLibs() {
    log "Copying Swift dependencies..."

    # Start from a clean slate: this directory must contain EXACTLY the current
    # toolchain's runtime libs plus the built products — never an accumulation of
    # past builds. Stale accumulation made APKs unreproducible across machines
    # (a lib present locally but missing on CI crashed Firebase test runs with
    # UnsatisfiedLinkError, and long-excluded libs kept shipping from old copies).
    rm -f "${LIBRARY_OUTPUT_DIRECTORY}"/*.so

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
        TARGET_LIB_DIR="swift-armv7/android"
    elif [ ${ANDROID_ABI} = "x86_64" ]; then
        TARGET_LIB_DIR="swift-x86_64/android"
    else
        TARGET_LIB_DIR="swift-aarch64/android"
    fi

    local LIB_FILES=(
        $(find "${SWIFT_SDK_PATH}/usr/lib/${TARGET_LIB_DIR}" -maxdepth 1 -type f -iname "*.so")
    )

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
        LIB_FILES=($(printf '%s\n' "${LIB_FILES[@]}" | grep --invert-match -i $EXCLUSIONS_STRING))
    fi

    for FILE_PATH in ${LIB_FILES[@]}
    do
        copyLib "${FILE_PATH}"
    done

    # libc++_shared.so comes from the NDK, not the Swift SDK
    if [ ${ANDROID_ABI} = "armeabi-v7a" ]; then
        local NDK_LIB_DIR="arm-linux-androideabi"
    elif [ ${ANDROID_ABI} = "x86_64" ]; then
        local NDK_LIB_DIR="x86_64-linux-android"
    else
        local NDK_LIB_DIR="aarch64-linux-android"
    fi
    local NDK_SYSROOT="${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/*/sysroot/usr/lib/${NDK_LIB_DIR}"
    copyLib ${NDK_SYSROOT}/libc++_shared.so
}
