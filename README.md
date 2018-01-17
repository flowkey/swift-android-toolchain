# swift-mac-toolchain
Build swift for Android from your Mac

## Installation

1. Clone the repo
2. Run `setup.sh`. This produces symlinks to your Mac's current Swift installation, and writes a toolchain `.json` file for SwiftPM (which annoyingly only accepts absolute paths).
3. Add the installation path to your `PATH` environment variable (e.g. in `~/.bash_profile` or equivalent)

## Usage

Run `sr swiftc` on individual files or `sr build` to build via SwiftPM.
