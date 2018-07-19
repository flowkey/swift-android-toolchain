# swift-android-toolchain
Build swift for Android from your Mac

## Installation

### Version A: for availability from the command line

1. Clone the repo
2. Add the installation path to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent)

### Version B: for availability within a specific repo

1. Add `swift-android-toolchain` as a git submodule
2. Use `/path-to-submodule/sr` whereever needed

## Usage

## From the command line

The four main commands are:
- `sr swift`: run Swift REPL
- `sr swiftc`: compile individual Swift files for Android
- `sr build`: build via SwiftPM for Android
- `sr copylibs`: copy swift libs from local Swift installation to your project

## In Android Studio

In your project’s `CMakeLists.txt`, add the following code after the `cmake_minimum_required(VERSION x.y.z)` declaration.

The following example could be used to build UIKit-cross-platform:

```
set(SwiftPM_DIR ./path/to/swift-android-toolchain)
find_package(SwiftPM REQUIRED)

add_swiftpm_library(UIKit
    PROJECT_DIRECTORY ./path/to/dir/containing/Package.swift # The directory, don't include the 'Package.swift' suffix
    PROJECT_DEPENDENCIES JNI # Optional space-separated list of Swift Product dependencies (built using add_swiftpm_library). Swift corelibs (e.g. Foundation, Dispatch) are implicitly available.
    C_FLAGS -I${UIKIT_DIRECTORY}/SDL/SDL2/include # Optional C Flags as space-delimited array.
    LINK_LIBS dl GLESv1_CM GLESv2 log android # Optionally linked external libraries, 'log', and 'android' are common. Added to the build's linker flags via '-l{LIBRARY_NAME}'
    MODULE_MAPS SDL/SDL2/include/module.modulemap SDL/SDL_ttf/include/module.modulemap SDL/sdl-gpu/include/module.modulemap # Optional list of clang module maps to include (transitively) in the SwiftPM build. Useful for making C public headers available to your Swift code.
)
```
