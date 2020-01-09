cmake_minimum_required(VERSION 3.16)

# Cache the toolchain's absolute path for later use
get_filename_component(SWIFT_TOOLCHAIN_ROOT ${CMAKE_CURRENT_LIST_DIR} ABSOLUTE)

# Gradle annoyingly only builds targets created by "add_library".
# As a workaround we create an empty library target and link it to every SwiftPM
# target we define, causing the linked targets to be be built and packaged in the APK.
# As a downside we end up with a libswiftPMBuildDummy.so, but it only adds ~1kb to the APK.
file(WRITE .empty.c "") # we need to build *something*, even if it's an empty file
add_library(swiftPMBuildDummy SHARED .empty.c)
add_dependencies(swiftPMBuildDummy unusedRandomTarget)

function(build)
    message("STATUS" "SwiftConfig.cmake ${PROJECT_DIRECTORY} ${ANDROID_ABI}")    

    add_custom_command(
        OUTPUT ${OUTPUT_LIBS}
        COMMAND ANDROID_ABI=${ANDROID_ABI} CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} "${SWIFT_TOOLCHAIN_ROOT}/swift-build.sh" ${PROJECT_DIRECTORY}
        WORKING_DIRECTORY ${PROJECT_DIRECTORY}
        DEPENDS ${SOURCE_FILES}
        VERBATIM
    )

    add_custom_target(unusedRandomTarget ALL
        DEPENDS ${OUTPUT_LIBS}
        VERBATIM
    )
endfunction(build)