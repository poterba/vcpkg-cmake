# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.

set(AUTO_VCPKG_GIT_REPOSITORY "https://github.com/Microsoft/vcpkg.git")

function (vcpkg_download)
    if (DEFINED AUTO_VCPKG_ROOT)
        return()
    endif ()
    set(AUTO_VCPKG_ROOT "${CMAKE_BINARY_DIR}/vcpkg")
    set(VCPKG_BUILD_DIR "${CMAKE_BINARY_DIR}/vcpkg-build")
    set(vcpkg_download_contents [===[
cmake_minimum_required(VERSION 3.5)
project(vcpkg-build)

include(ExternalProject)
ExternalProject_Add(vcpkg
            GIT_REPOSITORY @AUTO_VCPKG_GIT_REPOSITORY@
            GIT_SHALLOW ON
            SOURCE_DIR @AUTO_VCPKG_ROOT@
            PATCH_COMMAND ""
            CONFIGURE_COMMAND  ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            LOG_DOWNLOAD ON
            LOG_CONFIGURE ON
            LOG_INSTALL ON)
    ]===])
    string(REPLACE "@AUTO_VCPKG_GIT_REPOSITORY@" "${AUTO_VCPKG_GIT_REPOSITORY}" vcpkg_download_contents "${vcpkg_download_contents}")
    string(REPLACE "@AUTO_VCPKG_ROOT@" "${AUTO_VCPKG_ROOT}" vcpkg_download_contents "${vcpkg_download_contents}")
    file(WRITE "${VCPKG_BUILD_DIR}/CMakeLists.txt" "${vcpkg_download_contents}")

    execute_process(COMMAND "${CMAKE_COMMAND}" "-H${VCPKG_BUILD_DIR}" "-B${VCPKG_BUILD_DIR}")
    execute_process(COMMAND "${CMAKE_COMMAND}" "--build" "${VCPKG_BUILD_DIR}")
endfunction ()

function (vcpkg_bootstrap)
    find_program(AUTO_VCPKG_EXECUTABLE vcpkg PATHS ${AUTO_VCPKG_ROOT})
    if (NOT AUTO_VCPKG_EXECUTABLE)
        if (NOT DEFINED AUTO_VCPKG_SOURCE)
            set(AUTO_VCPKG_SOURCE ${CMAKE_CURRENT_FUNCTION_LIST_DIR})
        endif()
        if (NOT AUTO_VCPKG_SOURCE)
            message(FATAL_ERROR "VCPKG-AUTO failed to recognize own directory")
        endif()
        execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${AUTO_VCPKG_SOURCE}/vcpkgBootstrap.cmake" "${AUTO_VCPKG_ROOT}")
        execute_process(COMMAND ${CMAKE_COMMAND} -P "${AUTO_VCPKG_ROOT}/vcpkgBootstrap.cmake"
            WORKING_DIRECTORY ${AUTO_VCPKG_ROOT})
    endif ()
endfunction ()

function (vcpkg_download_and_bootstrap)
    if (NOT DEFINED AUTO_VCPKG_ROOT)
        if (NOT DEFINED ENV{AUTO_VCPKG_ROOT})
            vcpkg_download()
            set(AUTO_VCPKG_ROOT "${CMAKE_BINARY_DIR}/vcpkg" CACHE STRING "")
        else ()
            set(AUTO_VCPKG_ROOT "$ENV{AUTO_VCPKG_ROOT}" CACHE STRING "")
        endif ()
    message(STATUS "Setting AUTO_VCPKG_ROOT to ${AUTO_VCPKG_ROOT}")
    mark_as_advanced(AUTO_VCPKG_ROOT)
    endif ()
    vcpkg_bootstrap()
endfunction ()

function (vcpkg_configure)
    if (AUTO_VCPKG_EXECUTABLE AND DEFINED AUTO_VCPKG_ROOT)
        set(CMAKE_TOOLCHAIN_FILE
                "${AUTO_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
        return()
    endif ()

    vcpkg_download_and_bootstrap()
    message("Searching for vcpkg in ${AUTO_VCPKG_ROOT}")
    find_program(AUTO_VCPKG_EXECUTABLE
            vcpkg PATHS ${AUTO_VCPKG_ROOT})
    if (NOT AUTO_VCPKG_EXECUTABLE)
        message(FATAL_ERROR "Cannot find vcpkg executable in ${AUTO_VCPKG_ROOT}")
    endif ()
    mark_as_advanced(AUTO_VCPKG_EXECUTABLE)
    set(CMAKE_TOOLCHAIN_FILE
            "${AUTO_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
endfunction ()

function (vcpkg_install)
    vcpkg_configure()

    cmake_parse_arguments(_vcpkg_install "" "TRIPLET" "" ${ARGN})
    if (NOT ARGN)
        message(STATUS "vcpkg_install() called with no packages to install")
        return()
    endif ()

    if (NOT _vcpkg_install_TRIPLET)
        set(packages ${ARGN})
    else ()
        string(APPEND ":${_vcpkg_install_TRIPLET}" packages ${ARGN})
    endif ()
    string(JOIN ", " join ${packages})
    message(STATUS "vcpkg_install() called to install: ${join}")

    execute_process (COMMAND "${AUTO_VCPKG_EXECUTABLE}"
        "--downloads-root=${CMAKE_BINARY_DIR}/vcpkg-cache"
        "--binarysource=clear"
        "--binarysource=files,${CMAKE_BINARY_DIR}/vcpkg-store,readwrite"
        "install"
        ${packages})
endfunction ()
