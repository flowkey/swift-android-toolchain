# Copied from NDK's android.toolchain.cmake:
if(ANDROID_ABI STREQUAL armeabi-v7a)
  set(ANDROID_SYSROOT_ABI arm)
  set(ANDROID_TOOLCHAIN_NAME arm-linux-androideabi)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_TOOLCHAIN_NAME})
  set(ANDROID_HEADER_TRIPLE arm-linux-androideabi)
  set(CMAKE_SYSTEM_PROCESSOR armv7-a)
  set(ANDROID_LLVM_TRIPLE armv7-unknown-linux-android)
elseif(ANDROID_ABI STREQUAL arm64-v8a)
  set(ANDROID_SYSROOT_ABI arm64)
  set(CMAKE_SYSTEM_PROCESSOR aarch64)
  set(ANDROID_TOOLCHAIN_NAME aarch64-linux-android)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_TOOLCHAIN_NAME})
  set(ANDROID_LLVM_TRIPLE aarch64-unknown-linux-android)
  set(ANDROID_HEADER_TRIPLE aarch64-linux-android)
elseif(ANDROID_ABI STREQUAL x86_64)
  set(ANDROID_SYSROOT_ABI x86_64)
  set(CMAKE_SYSTEM_PROCESSOR x86_64)
  set(ANDROID_TOOLCHAIN_NAME x86_64-linux-android)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_ABI})
  set(ANDROID_LLVM_TRIPLE x86_64-unknown-linux-android)
  set(ANDROID_HEADER_TRIPLE x86_64-linux-android)
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
  set(ANDROID_HOST_TAG linux-x86_64)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
  set(ANDROID_HOST_TAG darwin-x86_64)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
  set(ANDROID_HOST_TAG windows-x86_64)
endif()

######################################################################

# Make a list that we then convert to a (space-delimited) string, below
set(SWIFT_FLAGS
    -g # always produce debug symbols
    -sdk ${ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}/sysroot
    -resource-dir ${SWIFT_SDK}/usr/lib/swift
    -tools-directory ${ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}/bin
    # -v
)

file(CREATE_LINK
    ${ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}/lib64/clang/14.0.6
    ${SWIFT_SDK}/usr/lib/swift/clang
    SYMBOLIC)

if(NOT CMAKE_BUILD_TYPE STREQUAL Debug)
    list(APPEND SWIFT_FLAGS -O)
endif()

list(JOIN SWIFT_FLAGS " " SWIFT_FLAGS)
set(CMAKE_Swift_FLAGS "${SWIFT_FLAGS}" CACHE INTERNAL "")

set(CMAKE_Swift_COMPILER_TARGET "${ANDROID_LLVM_TRIPLE}24" CACHE INTERNAL "")
