#!/bin/bash

## Fixes security/permission alerts that popup on MacOS Catalina (10.15.x)
## due to executing libs from the NDK that we downloaded during setup.

# common dependencies
DEPENDENCIES=(clang clang++ as ld ld.gold *.dylib llvm-strip)

# for each architecture
for ARCHITECTURE in armeabi-v7a arm-linux-androideabi aarch64-linux-android x86_64-linux-android;
do
    for ARCH_DEPENDENCY in ranlib ar strip;
    do
        DEPENDENCIES+=( $ARCHITECTURE-$ARCH_DEPENDENCY )
    done
done

for DEPENDENCY in ${DEPENDENCIES[@]};
do
 echo $DEPENDENCY
 # https://derflounder.wordpress.com/2012/11/20/clearing-the-quarantine-extended-attribute-from-downloaded-applications/
 find $ANDROID_NDK_PATH -name "$DEPENDENCY" -type f | xargs sudo xattr -r -d com.apple.quarantine
done
