set -e

cd "$(dirname $0)"
SWIFT_INSTALLATION_PATH="$PWD"

DISPATCH_BUILD="$SWIFT_INSTALLATION_PATH/dispatch-build"

rm -rf $DISPATCH_BUILD
mkdir -p $DISPATCH_BUILD
cd $DISPATCH_BUILD

cmake -G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_SYSTEM_NAME=Android \
	-DCMAKE_SYSROOT=$HOME/dev/android-toolchain/sysroot \
	-DENABLE_SWIFT=YES \
	-DBUILD_SHARED_LIBS=YES \
	-DCMAKE_SWIFT_COMPILER=$SWIFT_INSTALLATION_PATH/usr/bin/swiftc \
	-DENABLE_TESTING=OFF \
	-DCMAKE_ANDROID_ARCH_ABI=armeabi-v7a \
	-DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang \
	$SWIFT_INSTALLATION_PATH/swift-corelibs-libdispatch

cmake --build $DISPATCH_BUILD 

cp $DISPATCH_BUILD/src/libdispatch.so $SWIFT_INSTALLATION_PATH/usr/lib/swift/android
cp $DISPATCH_BUILD/src/swift/Dispatch.swift{doc,module} $SWIFT_INSTALLATION_PATH/usr/lib/swift/android/armv7/
