# swift-android-toolchain
Build swift for Android from your Mac


## Installation

### For use within a specific project

1. Add `swift-android-toolchain` as a git submodule
2. Use `./path-to-submodule/sr` whereever needed

`UIKit-cross-platform` uses this method (along with the Android Studio integration, below).


### For use globally from the command line

1. Clone the repo
2. Add the cloned destination to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent)


## Usage

### In Android Studio

In your project’s `CMakeLists.txt`, add the following code after the `cmake_minimum_required(VERSION x.y.z)` declaration.


```
set(SwiftPM_DIR ./path/to/swift-android-toolchain) # can be a relative path (e.g. a git submodule)
find_package(SwiftPM REQUIRED)

# Minimal Example:
add_swiftpm_library(DemoLibrary # Name of the Swift Package Manager 'Product' as listed in Package.swift
    # Directory containing Package.swift. Don't include the 'Package.swift' suffix:
    PROJECT_DIRECTORY ./path/to/swift/package
)

# Advanced example (based on what we use to build UIKit-cross-platform):
add_swiftpm_library(UIKit
    PROJECT_DIRECTORY ./path/to/project
    # Optional space-separated list of Swift Product dependencies (built using add_swiftpm_library). Swift corelibs (e.g. Foundation, Dispatch) are implicitly available:
    PROJECT_DEPENDENCIES JNI
    # Optional C Flags as space-delimited array:
    C_FLAGS -I${UIKIT_DIRECTORY}/SDL/SDL2/include
    # Optionally linked external libraries, 'log', and 'android' are common. Added to the build's linker flags via '-l{LIBRARY_NAME}':
    LINK_LIBS dl GLESv1_CM GLESv2 log android
    # Optional list of clang module maps to include (transitively) in the SwiftPM build. Useful for making C public headers available to your Swift code:
    MODULE_MAPS SDL/SDL2/include/module.modulemap SDL/SDL_ttf/include/module.modulemap SDL/sdl-gpu/include/module.modulemap
)
```

### From the command line

The four main commands are:
- `sr build`: build via SwiftPM for Android
- `sr swiftc`: compile individual Swift files for Android. Builds a `.so` library by default but advanced users can build executables and run them on rooted devices.
- `sr copylibs (destination)`: copy Swift libs from local Swift installation to `destination` or to the current directory if none specified. Not needed if using the Android Studio integration (below).


## Credits

This toolchain is only possible by standing on the shoulders of giants.

Many thanks to [Gonzalo Lorralde](https://github.com/gonzalolarralde) for [swifty-robot-environment](https://github.com/gonzalolarralde/swifty-robot-environment) and [John Holdsworth](https://github.com/johnno1962) for his [android_toolchain](https://github.com/SwiftJava/android_toolchain). And to the Swift community as a whole for their ongoing work at making the language great.
