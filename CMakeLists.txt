cmake_minimum_required(VERSION 3.20)

project(scratchbird_driver LANGUAGES C CXX)

option(SB_BUILD_CPP "Build C/C++ client library" ON)
option(SB_BUILD_ODBC "Build ODBC driver" ON)
option(SB_BUILD_CLI "Build CLI tools" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if (SB_BUILD_CPP)
    add_subdirectory(tracks/beta/drivers/cpp)
endif()

if (SB_BUILD_ODBC)
    add_subdirectory(tracks/alpha/drivers/odbc)
endif()

if (SB_BUILD_CLI)
    add_subdirectory(tracks/alpha/drivers/cli)
endif()
