#!/bin/bash

set -e

ORIGINAL_PWD="$PWD"
cd "$(dirname $0)"
export SWIFT_INSTALLATION_PATH="$PWD"
export PATH="$SWIFT_INSTALLATION_PATH/usr/Darwin:$TOOLCHAIN/bin:$PATH"
export SYSROOT="$SWIFT_INSTALLATION_PATH"
export SWIFT_ANDROID_BUILDPATH="/tmp"
cd "$ORIGINAL_PWD"

cmake -G Ninja
-DSWIFT_ANDROID_SDK=${ANDROID_SDK_ROOT}/Android.sdk-${ANDROID_ABI}
-C ${SWIFT_INSTALLATION_PATH}/../../caches.cmake
-C $(Build.SourcesDirectory)/cmake/caches/android-${{ parameters.arch }}-swift-flags.cmake
-DCMAKE_TOOLCHAIN_FILE=$(Build.SourcesDirectory)/cmake/toolchains/android.toolchain.ndk20.cmake
-DCMAKE_C_COMPILER=clang
-DCMAKE_CXX_COMPILER=clang++
-DCMAKE_BUILD_TYPE=RelWithDebInfo
-DCMAKE_SWIFT_COMPILER=swiftc
-DCMAKE_INSTALL_PREFIX=$(install.directory)
-DCURL_LIBRARY=$(curl.directory)/usr/lib/libcurl.a
-DCURL_INCLUDE_DIR=$(curl.directory)/usr/include
-DICU_INCLUDE_DIR=$(icu.directory)/usr/include
-DICU_UC_LIBRARY=$(icu.directory)/usr/lib/libicuuc$(icu.version).so
-DICU_UC_LIBRARY_RELEASE=$(icu.directory)/usr/lib/libicuuc$(icu.version).so
-DICU_I18N_LIBRARY=$(icu.directory)/usr/lib/libicuin$(icu.version).so
-DICU_I18N_LIBRARY_RELEASE=$(icu.directory)/usr/lib/libicuin$(icu.version).so
-DLIBXML2_LIBRARY=$(xml2.directory)/usr/lib/libxml2.a
-DLIBXML2_INCLUDE_DIR=$(xml2.directory)/usr/include/libxml2
-DFOUNDATION_PATH_TO_LIBDISPATCH_SOURCE=$(Build.SourcesDirectory)/swift-corelibs-libdispatch
-DFOUNDATION_PATH_TO_LIBDISPATCH_BUILD=$(Build.StagingDirectory)/libdispatch
$(Build.SourcesDirectory)/swift-corelibs-foundation
..
