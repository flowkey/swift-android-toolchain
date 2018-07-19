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

The four main commands are:
- `sr swift`: run Swift REPL
- `sr swiftc`: compile individual Swift files for Android
- `sr build`: build via SwiftPM for Android
- `sr copylibs`: copy swift libs from local Swift installation to your project
