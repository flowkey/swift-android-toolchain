cmake_minimum_required(VERSION 3.4.1)
include(CMakeParseArguments)

# Only support armv7a for now:
if(ANDROID_LLVM_TRIPLE AND NOT (ANDROID_LLVM_TRIPLE MATCHES ^armv7-none-linux-androideabi))
    message(FATAL_ERROR "${ANDROID_LLVM_TRIPLE} is not (yet) supported by Swift, please add `android.defaultConfig.ndk.abiFilters \"armeabi-v7a\"` to your app's build.gradle")
endif()


# Cache the toolchain's absolute path for later use
get_filename_component(SWIFT_TOOLCHAIN_ROOT ${CMAKE_CURRENT_LIST_DIR} ABSOLUTE)


# Set SwiftPM's build path explicitly to
#  a) keep the android build in one place, and
#  b) allow separate SwiftPM Projects built for the same Android Project to depend on each other more easily
set(SWIFTPM_BUILD_PATH ${PROJECT_SOURCE_DIR}/.externalNativeBuild/swiftpm)


# Android Studio annoyingly only builds targets created by "add_library".
# As a workaround we create an empty library target and link it to every SwiftPM
# target we define, causing the linked targets to be be built and packaged in the APK.
# As a downside we end up with a libswiftPMBuildDummy.so, but it only adds ~1kb to the APK.
file(WRITE .empty.c "") # we need to build *something*, even if it's an empty file
add_library(swiftPMBuildDummy SHARED .empty.c)


# The main public API exposed by this package:
function(add_swiftpm_library PRODUCT_NAME)
    cmake_parse_arguments(${PRODUCT_NAME}
        "" # Options (with no params)
        "PROJECT_DIRECTORY" # Single-argument params
        "PROJECT_DEPENDENCIES;C_FLAGS;SWIFT_FLAGS;LINK_LIBS;LINKER_FLAGS;MODULE_MAPS" # Multi-argument params
        ${ARGN})

    if(NOT ${PRODUCT_NAME}_PROJECT_DIRECTORY)
        message(FATAL_ERROR "You must specify SwiftPM Product \"${PRODUCT_NAME}\"'s `PROJECT_DIRECTORY`")
    endif()


    set(PROJECT_DIRECTORY ${${PRODUCT_NAME}_PROJECT_DIRECTORY})
    get_filename_component(PROJECT_DIRECTORY ${PROJECT_DIRECTORY} ABSOLUTE)

    # Check we have a Swift Package Manifest at the directory specified
    if(NOT EXISTS ${PROJECT_DIRECTORY}/Package.swift)
        message(FATAL_ERROR "Couldn't find a Swift Package at ${PRODUCT_NAME}'s PROJECT_DIRECTORY, ${PROJECT_DIRECTORY}")
    endif()


    # Parse the argument lists into arguments for SwiftPM
    foreach(FLAG IN LISTS ${PRODUCT_NAME}_C_FLAGS)
        set(SWIFTPM_ARGS "${SWIFTPM_ARGS} -Xcc ${FLAG}")
    endforeach(FLAG)

    foreach(FLAG IN LISTS ${PRODUCT_NAME}_SWIFT_FLAGS)
        set(SWIFTPM_ARGS "${SWIFTPM_ARGS} -Xswiftc ${FLAG}")
    endforeach(FLAG)

    foreach(FLAG IN LISTS ${PRODUCT_NAME}_LINKER_FLAGS)
        set(SWIFTPM_ARGS "${SWIFTPM_ARGS} -Xlinker ${FLAG}")
    endforeach(FLAG)

    foreach(DEPENDENCY IN LISTS ${PRODUCT_NAME}_LINK_LIBS)
        set(SWIFTPM_ARGS "${SWIFTPM_ARGS} -Xlinker -l${DEPENDENCY}")
    endforeach(DEPENDENCY)

    foreach(MODULE_MAP IN LISTS ${PRODUCT_NAME}_MODULE_MAPS)
        set(SWIFTPM_ARGS "${SWIFTPM_ARGS} -Xcc -fmodule-map-file=${PROJECT_DIRECTORY}/${MODULE_MAP}")
    endforeach(MODULE_MAP)

    foreach(DEPENDENCY IN LISTS ${PRODUCT_NAME}_PROJECT_DEPENDENCIES)
        # We *prepend* existing dependency args, because *later* arguments take precendence:
        set(SWIFTPM_ARGS "-Xswiftc -l${DEPENDENCY} ${${DEPENDENCY}_SWIFTPM_ARGS} ${SWIFTPM_ARGS}")
    endforeach(DEPENDENCY)


    # The following GLOB is a big optimization, but means that adding or removing a source
    # file without changing any other will require a "Refresh Linked C++ Projects" to be recognized:
    file(GLOB_RECURSE SOURCE_FILES RELATIVE ${CMAKE_SOURCE_DIR} "${PROJECT_DIRECTORY}/*.swift" "${PROJECT_DIRECTORY}/*.c" "${PROJECT_DIRECTORY}/*.cpp")

    # Actually build via SwiftPM
    set(BUILT_PRODUCT_FILEPATH "${SWIFTPM_BUILD_PATH}/${BUILD_CONFIGURATION}/lib${PRODUCT_NAME}.so")

    add_custom_command(
        OUTPUT ${BUILT_PRODUCT_FILEPATH}
        COMMAND ${SWIFT_TOOLCHAIN_ROOT}/sr build -Xswiftc -g --product ${PRODUCT_NAME} --configuration ${BUILD_CONFIGURATION} --build-path ${SWIFTPM_BUILD_PATH} ${SWIFTPM_ARGS}
        DEPENDS ${SOURCE_FILES} ${${PRODUCT_NAME}_PROJECT_DEPENDENCIES}
        WORKING_DIRECTORY ${PROJECT_DIRECTORY}
        COMMENT "Compiling ${PRODUCT_NAME}. If this worked before and you now get an error saying 'xyz.swift was not found', run 'Build->Refresh Linked C++ Projects' in Android Studio." # or run CMake again
        VERBATIM
    )

    bundle_lib(${PRODUCT_NAME} ${BUILT_PRODUCT_FILEPATH} REQUIRES_BUILD)

    # This will be reused when building other SwiftPM libs dependent on this one:
    set(${PRODUCT_NAME}_SWIFTPM_ARGS ${SWIFTPM_ARGS} PARENT_SCOPE)
endfunction(add_swiftpm_library)


# We put the following into functions to avoid polluting the global namespace with their variables:
function(set_build_configuration)
    set(ALLOWED_BUILD_CONFIGURATIONS debug release)
    string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_CONFIGURATION)

    if(NOT BUILD_CONFIGURATION)
        message("No build configuration specified, defaulting to 'debug'")
        message("Set CMAKE_BUILD_TYPE to 'debug' or 'release' to fix this")
        set(BUILD_CONFIGURATION debug)
    else()
        # Ensure the BUILD_CONFIGURATION selected is correct
        # CMake doesn't seem to have a list(CONTAINS) function, so use this weird hack:
        set(REMAINING_BUILD_CONFIGURATIONS ALLOWED_BUILD_CONFIGURATIONS)
        list(REMOVE_ITEM REMAINING_BUILD_CONFIGURATIONS BUILD_CONFIGURATION)
        list(LENGTH REMAINING_BUILD_CONFIGURATIONS REMAINING_BUILD_CONFIGURATION_COUNT)

        if(NOT REMAINING_BUILD_CONFIGURATION_COUNT EQUAL 1)
            message(WARNING "The CMAKE_BUILD_TYPE provided, \"${CMAKE_BUILD_TYPE}\", did not match one of ${ALLOWED_BUILD_CONFIGURATIONS}. Defaulting to 'debug'.")
            set(BUILD_CONFIGURATION debug)
        endif()
    endif()

    # Deliberate side-effect:
    set(BUILD_CONFIGURATION ${BUILD_CONFIGURATION} PARENT_SCOPE)
endfunction(set_build_configuration)

set_build_configuration()


function(bundle_lib LIBRARY LIBRARY_INPUT_FILEPATH)
    cmake_parse_arguments(BUNDLE "REQUIRES_BUILD" "" "" ${ARGN})
    set(LIBRARY_OUTPUT_FILEPATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/lib${LIBRARY}.so")

    if(BUNDLE_REQUIRES_BUILD)
        add_custom_command(
            OUTPUT ${LIBRARY_OUTPUT_FILEPATH}
            COMMAND ${CMAKE_COMMAND} -E copy ${LIBRARY_INPUT_FILEPATH} ${LIBRARY_OUTPUT_FILEPATH}
            DEPENDS ${LIBRARY_INPUT_FILEPATH} # Ensure the library is built before trying to copy it
        )
    else()
        add_custom_command(
            OUTPUT ${LIBRARY_OUTPUT_FILEPATH}
            COMMAND ${CMAKE_COMMAND} -E copy ${LIBRARY_INPUT_FILEPATH} ${LIBRARY_OUTPUT_FILEPATH}
        )
    endif()

    # This is what actually gets "built" when it's dependended upon as a library
    # (or - when CMake is run from the command line - as a part of the default ALL target)
    add_custom_target(${LIBRARY}_BUILD_TARGET ALL DEPENDS ${LIBRARY_OUTPUT_FILEPATH})

    # Cause the library to actually get built by Android Studio's CMake implementation (see swiftPMBuildDummy):
    add_library(${LIBRARY} SHARED IMPORTED)
    set_target_properties(${LIBRARY} PROPERTIES IMPORTED_LOCATION ${LIBRARY_OUTPUT_FILEPATH})
    target_link_libraries(swiftPMBuildDummy ${LIBRARY})
endfunction(bundle_lib)



# Bundle Swift's core library dependencies in the APK
function(bundle_swift_corelibs)
    set(
        SWIFT_CORE_DEPENDENCIES
        c++_shared curl dispatch Foundation scudata scui18n scuuc swiftCore swiftGlibc swiftRemoteMirror swiftSwiftOnoneSupport xml2
        CACHE STRING "Swift core library dependencies that will be bundled with the app")

    set(CORE_DEP_LIBRARY_PATH ${SWIFT_TOOLCHAIN_ROOT}/usr/lib/swift/android)

    # Add a dependency from our build dummy to the corelibs in order to force Android Studio to package them
    foreach(CORE_DEP IN LISTS SWIFT_CORE_DEPENDENCIES)
        bundle_lib(${CORE_DEP} ${CORE_DEP_LIBRARY_PATH}/lib${CORE_DEP}.so)
    endforeach(CORE_DEP)
endfunction(bundle_swift_corelibs)

bundle_swift_corelibs()


# Debugging only:
# function(print_all_vars)
#     get_cmake_property(_variableNames VARIABLES)
#     list (SORT _variableNames)
#     foreach (_variableName ${_variableNames})
#         message(STATUS "${_variableName}=${${_variableName}}")
#     endforeach()
# endfunction(print_all_vars)
# print_all_vars()
