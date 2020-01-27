cmake_minimum_required(VERSION 3.16)

# Cache the toolchain's absolute path for later use
get_filename_component(SWIFT_TOOLCHAIN_ROOT ${CMAKE_CURRENT_LIST_DIR} ABSOLUTE)

# Gradle annoyingly only builds targets created by "add_library".
# As a workaround we create an empty library target and link it to every SwiftPM
# target we define, causing the linked targets to be be built and packaged in the APK.
# As a downside we end up with a swiftBuildDummy.so, but it only adds ~1kb to the APK.
file(WRITE .empty.c "") # we need to build *something*, even if it's an empty file
add_library(swiftBuildDummy SHARED .empty.c)
add_dependencies(swiftBuildDummy allTarget)

set(LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}")

# Path to a file which will never be built by cmake and therefore never exists.
# Referencing this file as dependency in `allTarget` ensures `swift-build.sh`
# will always be invoked when building via gradle.
# If there is actually nothing to do `swift-build.sh` will exit immediately.
set(NEVER_EXISTING_OUTPUT ./nop)

function(build_swift_project)
    execute_process(
        COMMAND bash -c "LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} ANDROID_ABI=${ANDROID_ABI} CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${SWIFT_TOOLCHAIN_ROOT}/swift-build.sh -configure ${PROJECT_DIRECTORY}"
    )

    add_custom_command(
        OUTPUT NEVER_EXISTING_OUTPUT
        COMMAND LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} ANDROID_ABI=${ANDROID_ABI} CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${SWIFT_TOOLCHAIN_ROOT}/swift-build.sh ${PROJECT_DIRECTORY}
        WORKING_DIRECTORY ${PROJECT_DIRECTORY}
        VERBATIM
    )

    add_custom_target(allTarget ALL
        DEPENDS NEVER_EXISTING_OUTPUT
        VERBATIM
    )
endfunction(build_swift_project)