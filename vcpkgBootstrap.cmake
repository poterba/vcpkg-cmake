# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.

find_program(VCPKG_EXECUTABLE vcpkg PATHS "${CMAKE_CURRENT_LIST_DIR}")

if (NOT VCPKG_EXECUTABLE)
    if (WIN32)
        set(VCPKG_BUILD_COMMAND "${CMAKE_CURRENT_LIST_DIR}/bootstrap-vcpkg.bat")
    else()
        set(VCPKG_BUILD_COMMAND "${CMAKE_CURRENT_LIST_DIR}/bootstrap-vcpkg.sh")
    endif()

    list(APPEND VCPKG_BUILD_COMMAND "--allowAppleClang" "--disableMetrics")
    execute_process(COMMAND ${VCPKG_BUILD_COMMAND} WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
endif()
