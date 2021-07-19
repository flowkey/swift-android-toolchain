# swift-android-toolchain

Build Swift for Android from Mac

## Installation

### For use within a specific project

1. Add `swift-android-toolchain` as a git submodule
2. Use `./path-to-submodule/swift-build.sh` wherever needed

[UIKit-cross-platform](https://github.com/flowkey/UIKit-cross-platform) uses this method (along with the Android Studio integration, below).

### For use globally from the command line

1. Clone the repo
1. Add the cloned destination to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent)

## Usage

### In Android Studio / Gradle

You probably want Gradle to compile your native sources automatically when building the android app. In order to achieve this, you have to create another `CMakeLists.txt` file and reference it from `app/build.gradle`.

```Gradle
externalNativeBuild {
    cmake {
        version "3.16.2"
        path "CMakeLists.txt" // android/app/src/CMakeLists.txt
    }
}
```

In `android/app/src/CMakeLists.txt`, add the following code after the `cmake_minimum_required(VERSION x.y.z)` declaration.

```CMake
# destination of project level CMakeLists.txt for building native sources
get_filename_component(PROJECT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/../../ ABSOLUTE)

# path to swift-android-toolchain
set(BuildSwiftProject_DIR ../../swift-android-toolchain)
find_package(BuildSwiftProject REQUIRED)

build_swift_project(
    PROJECT_DIRECTORY ${PROJECT_DIRECTORY}
)
```

Check out [getting-started](https://github.com/flowkey/UIKit-cross-platform/tree/master/samples/getting-started) for a working example.

### From the command line

```bash
ANDROID_ABI="armeabi-v7a" CMAKE_BUILD_TYPE="Debug" swift-build.sh
```

#### For users on MacOS Catalina (10.15.x)

Since use a downloaded version of the Android NDK in this build, MacOS Catalina complains about security issues. Running the build might show you alerts for every library from the NDK that is invoked by the build script, asking to grant permissions.

Running the [`fixCatalinaPermissions.sh`](fixCatalinaPermissions.sh) script, after setup, but before invoking the build, should resolve this issue.

## Credits

Making this toolchain was only possible by standing on the shoulders of giants.

Many thanks to [Vlad Gorlov](https://github.com/vgorloff) for his great work with the [swift-everywhere-toolchain](https://github.com/vgorloff/swift-everywhere-toolchain), [Gonzalo Lorralde](https://github.com/gonzalolarralde) for [swifty-robot-environment](https://github.com/gonzalolarralde/swifty-robot-environment) and [John Holdsworth](https://github.com/johnno1962) for his [android_toolchain](https://github.com/SwiftJava/android_toolchain). And to the Swift community as a whole for their ongoing work at making the language great.
