#!/bin/bash

set -e

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
source "${SCRIPT_ROOT}/setup.sh"

# readonly SDK_DIRNAME=swift-android
readonly BUILD_TYPE=${BUILD_TYPE:-release}
readonly SCRATCH_PATH="swiftpm-build"

if [ -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ]
then
    cp -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ${SCRATCH_PATH}/${BUILD_TYPE}.yaml
fi

for arg in "$@"
do
    case $arg in
        --static-swift-stdlib)
            STATIC_SWIFT_STDLIB=1
        ;;
    esac
done

if [ ${ANDROID_ABI} = "armeabi-v7a" ]; then
    ANDROID_ARCH="armv7"
    TARGET_TRIPLE="armv7-unknown-linux-androideabi24"
    TARGET_LIB_DIR="arm-linux-androideabi"
elif [ ${ANDROID_ABI} = "x86_64" ]; then
    ANDROID_ARCH="x86_64"
    TARGET_TRIPLE="x86_64-unknown-linux-android24"
    TARGET_LIB_DIR="x86_64-linux-android"
else # assume arm64
    ANDROID_ARCH="aarch64"
    TARGET_TRIPLE="aarch64-unknown-linux-android24"
    TARGET_LIB_DIR="aarch64-linux-android"
fi

if [ "${STATIC_SWIFT_STDLIB}" ]
then
    readonly DESTINATION_FILE="${SCRIPT_ROOT}/${ANDROID_ABI}_static.json"
else
    readonly DESTINATION_FILE="${SCRIPT_ROOT}/${ANDROID_ABI}.json"
fi

if [ ! -f "${DESTINATION_FILE}" ]; then
    if [ "${STATIC_SWIFT_STDLIB}" ]
    then
cat <<- EOF > "${DESTINATION_FILE}"
{
    "version": 1,
    "target": "${TARGET_TRIPLE}",
    "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
    "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
    "extra-cc-flags": ["-fPIC", "-DSTATIC_SWIFT_STDLIB"],
    "extra-swiftc-flags": [
        "-L",
        "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift_static/android/${ANDROID_ARCH}",
        "-DSTATIC_SWIFT_STDLIB",
        "-resource-dir",
        "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift_static",
        "-tools-directory",
        "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin"
    ],
    "extra-cpp-flags": ["-lstdc++"]
}
EOF
    else
cat <<- EOF > "${DESTINATION_FILE}"
{
    "version": 1,
    "target": "${TARGET_TRIPLE}",
    "toolchain-bin-dir": "${TOOLCHAIN_PATH}/usr/bin",
    "sdk": "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/sysroot",
    "extra-cc-flags": ["-fPIC"],
    "extra-swiftc-flags": [
        "-L",
        "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/${TARGET_LIB_DIR}",
        "-resource-dir",
        "${SCRIPT_ROOT}/sdk/${SDK_DIRNAME}/usr/lib/swift",
        "-tools-directory",
        "${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/bin"
    ],
    "extra-cpp-flags": ["-lstdc++"]
}
EOF
    fi
fi

${TOOLCHAIN_PATH}/usr/bin/swift package update \
    --disable-index-store \
    --scratch-path ${SCRATCH_PATH} 

# --disable-index-store works around compiler crash in swift 5.7 toolchain:
# adding a --scratch-path per ABI makes rebuilding faster
${TOOLCHAIN_PATH}/usr/bin/swift build \
    --disable-index-store \
    --scratch-path ${SCRATCH_PATH} \
    --destination "${DESTINATION_FILE}" \
    -c ${BUILD_TYPE} \
    $@

cp -f ${SCRATCH_PATH}/${BUILD_TYPE}.yaml ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml

if [ "$LIBRARY_OUTPUT_DIRECTORY" ]
then
    copySwiftDependencyLibs
    mkdir -p ${LIBRARY_OUTPUT_DIRECTORY}
    cp -f "${SCRATCH_PATH}/${BUILD_TYPE}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
fi
