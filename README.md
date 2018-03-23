# swift-mac-toolchain
Build swift for Android from your Mac

## Installation

### Version A: for availability in the command line

1. Clone the repo
2. Add the installation path to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent). *Note: If you previously had swiftyrobot installed, remove its directory from your PATH here too! This is a complete replacement for `sr`*

### Version B: for availability within a specific repo

1. Add `swift-mac-toolchain` as a submodule
2. Use `/path-to-submodule/sr` whereever needed

## Usage

Run `sr swiftc` on individual files or `sr build` to build via SwiftPM.
