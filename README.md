# swift-android-toolchain
Build swift for Android from your Mac

## Installation

### Version A: for availability in the command line

1. Clone the repo
2. Add the installation path to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent)

### Version B: for availability within a specific repo

1. Add `swift-android-toolchain` as a submodule
2. Use `/path-to-submodule/sr` whereever needed

## Usage

Run `sr swiftc` on individual files or `sr build` to build via SwiftPM.
