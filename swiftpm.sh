#!/bin/bash

set -e

readonly SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD) # path of this file
source "${SCRIPT_ROOT}/setup.sh"

if [ ! -f "${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift/clang" ]
then
    ln -fs \
        ${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${HOST}/lib64/clang/14.0.6 \
        ${SCRIPT_ROOT}/sdk/${ANDROID_ABI}/usr/lib/swift/clang
fi

readonly BUILD_TYPE=${BUILD_TYPE:-release}
readonly SCRATCH_PATH="swiftpm-build"

if [ -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ]
then
    cp -f ${SCRATCH_PATH}/${ANDROID_ABI}-${BUILD_TYPE}.yaml ${SCRATCH_PATH}/${BUILD_TYPE}.yaml
fi

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
    mkdir -p ${LIBRARY_OUTPUT_DIRECTORY}
    cp -f "${SCRATCH_PATH}/${BUILD_TYPE}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
fi