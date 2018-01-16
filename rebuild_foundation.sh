#!/bin/bash
#### swifty-robot-environment ####
#
# Standalone rebuild of foundation from source
#
# Dependencies: swift android toolchain from http://johnholdsworth.com/android_toolchain.tgz
#

USER_DIR="$PWD"
cd "$(dirname $0)"
export SWIFT_INSTALLATION_PATH="$PWD"
export PATH="$SWIFT_INSTALLATION_PATH/usr/Darwin:$TOOLCHAIN/bin:$PATH"
export SYSROOT="$SWIFT_INSTALLATION_PATH"
export SWIFT_ANDROID_BUILDPATH="/tmp"
cd "$USER_DIR"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Foundation rebuild only available on macOS"
    exit 1
fi

if [[ ! -d swift-corelibs-foundation ]]; then
    git clone http://github.com/SwiftJava/swift-corelibs-foundation &&
    cd swift-corelibs-foundation && git checkout android-toolchain-1.0 && cd -
fi &&

	# Build foundation
	# Remove default foundation implementation and fetch the version with android support

pushd swift-corelibs-foundation &&

    export PKG_CONFIG_PATH="$SWIFT_INSTALLATION_PATH/pkgconfig" &&
    rm -rf "$SWIFT_INSTALLATION_PATH/usr/lib/swift/CoreFoundation" &&

    export CLANG="$(dirname $(readlink $SWIFT_INSTALLATION_PATH/usr/bin/swift))/clang" &&
    export BUILD_DIR="$SWIFT_ANDROID_BUILDPATH/foundation-macosx-x86_64" &&

    env \
        SWIFTC="$SWIFT_INSTALLATION_PATH/usr/Darwin/swiftc" \
        SWIFT="$SWIFT_INSTALLATION_PATH/usr/Darwin/swift" \
        SDKROOT="$SWIFT_ANDROID_BUILDPATH/swift-macosx-x86_64" \
        DSTROOT="/" \
        PREFIX="/usr/" \
        CFLAGS="-DDEPLOYMENT_TARGET_ANDROID -DDEPLOYMENT_ENABLE_LIBDISPATCH --sysroot=$SWIFT_INSTALLATION_PATH/ndk-android-21 -I${SDKROOT}/lib/swift -I$SWIFT_INSTALLATION_PATH/ndk-android-21/support/include -I$PWD/closure" \
        SWIFTCFLAGS="-DDEPLOYMENT_TARGET_ANDROID -DDEPLOYMENT_ENABLE_LIBDISPATCH" \
        LDFLAGS="-fuse-ld=gold --sysroot=$SWIFT_INSTALLATION_PATH/ndk-android-21 -L$SWIFT_INSTALLATION_PATH/usr/Darwin -ldispatch " \
        SDKROOT=$SWIFT_INSTALLATION_PATH/usr \
        ./configure \
            Debug \
            --target=armv7-none-linux-androideabi \
            --sysroot=$SWIFT_INSTALLATION_PATH/ndk-android-21 \
            -DXCTEST_BUILD_DIR=$SWIFT_ANDROID_BUILDPATH/xctest-linux-x86_64 \
            -DLIBDISPATCH_SOURCE_DIR=$SWIFT_INSTALLATION_PATH/usr/lib/swift \
            -DLIBDISPATCH_BUILD_DIR=$SWIFT_INSTALLATION_PATH/usr/lib/swift &&

    # Prepend SYSROOT env variable to ninja.build script
    # SYSROOT is not being passed from build.py / script.py to the ninja file yet
    echo "SYSROOT=$SYSROOT" > build.ninja.new &&
    cat build.ninja >> build.ninja.new &&
    mv -f build.ninja.new build.ninja &&

    ninja &&
			
    # There's no installation script for foundation yet, so the installation needs to be done manually.
    # Apparently the installation for the main script is in swift repo.
    rsync -a $BUILD_DIR/Foundation/usr/lib/swift/CoreFoundation $SWIFT_INSTALLATION_PATH/usr/lib/swift &&
    cp -v $BUILD_DIR/Foundation/libFoundation.so $SWIFT_INSTALLATION_PATH/usr/lib/swift/android/ &&
    cp -v $BUILD_DIR/Foundation/Foundation.swift* $SWIFT_INSTALLATION_PATH/usr/lib/swift/android/armv7/ &&

popd

