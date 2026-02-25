cmake_minimum_required(VERSION 3.20)

project(scratchbird_cli LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(SB_BUILD_CLI_FDW "Build FDW-backed CLI tools (pg/mysql/firebird)" OFF)
set(SB_ENGINE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../ScratchBird" CACHE PATH
    "Path to ScratchBird engine source tree (for FDW CLI linkage)")
set(SB_ENGINE_BUILD_DIR "${SB_ENGINE_SOURCE_DIR}/build" CACHE PATH
    "Path to ScratchBird engine build tree (for FDW CLI linkage)")

set(SB_CPP_DRIVER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../beta/drivers/cpp")
if (NOT TARGET scratchbird_client)
    add_subdirectory("${SB_CPP_DRIVER_DIR}" "${CMAKE_BINARY_DIR}/scratchbird_cpp")
endif()

add_executable(sb_isql sb_isql.cpp)
add_executable(sb_admin sb_admin.cpp)
add_executable(sb_backup sb_backup.cpp)
add_executable(sb_security sb_security.cpp)
add_executable(sb_verify sb_verify.cpp)
add_executable(sbdriver_conformance sbdriver_conformance.cpp)

set(cli_targets
    sb_isql
    sb_admin
    sb_backup
    sb_security
    sb_verify
    sbdriver_conformance
)

if (SB_BUILD_CLI_FDW)
    add_executable(sb_pg_isql sb_pg_isql.cpp)
    add_executable(sb_my_isql sb_my_isql.cpp)
    add_executable(sb_fb_isql sb_fb_isql.cpp)
    list(APPEND cli_targets sb_pg_isql sb_my_isql sb_fb_isql)

    set(fdw_cli_targets sb_pg_isql sb_my_isql sb_fb_isql)
    set(SB_ENGINE_INCLUDE_DIR "${SB_ENGINE_SOURCE_DIR}/include")
    set(SB_ENGINE_LIB_DIR "${SB_ENGINE_BUILD_DIR}/src")
    set(SB_ENGINE_FDW_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_fdw.a")
    set(SB_ENGINE_SBLR_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_sblr.a")
    set(SB_ENGINE_PARSER_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_parser.a")
    set(SB_ENGINE_CORE_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_core.a")

    set(sb_engine_libs_ready TRUE)
    foreach(required_path IN LISTS SB_ENGINE_FDW_LIB SB_ENGINE_SBLR_LIB SB_ENGINE_PARSER_LIB SB_ENGINE_CORE_LIB)
        if (NOT EXISTS "${required_path}")
            message(WARNING "Missing required ScratchBird engine artifact: ${required_path}")
            set(sb_engine_libs_ready FALSE)
        endif()
    endforeach()

    if (NOT EXISTS "${SB_ENGINE_INCLUDE_DIR}")
        message(WARNING "Missing ScratchBird engine include directory: ${SB_ENGINE_INCLUDE_DIR}")
        set(sb_engine_libs_ready FALSE)
    endif()

    if (NOT sb_engine_libs_ready)
        message(FATAL_ERROR
            "SB_BUILD_CLI_FDW=ON requires ScratchBird engine headers and libs. "
            "Build ScratchBird first or override SB_ENGINE_SOURCE_DIR/SB_ENGINE_BUILD_DIR.")
    endif()

    find_package(OpenSSL REQUIRED)
    find_package(Threads REQUIRED)
    foreach(target IN LISTS fdw_cli_targets)
        target_include_directories(${target} BEFORE PRIVATE "${SB_ENGINE_INCLUDE_DIR}")
        target_link_libraries(${target}
            PRIVATE
                "${SB_ENGINE_FDW_LIB}"
                "${SB_ENGINE_SBLR_LIB}"
                "${SB_ENGINE_PARSER_LIB}"
                "${SB_ENGINE_CORE_LIB}"
                OpenSSL::SSL
                OpenSSL::Crypto
                Threads::Threads
        )
    endforeach()
endif()

foreach(target IN LISTS cli_targets)
    if (target STREQUAL "sbdriver_conformance")
        target_include_directories(${target}
            PRIVATE
                "${SB_CPP_DRIVER_DIR}/include"
        )
    else()
        target_include_directories(${target}
            PRIVATE
                ${CMAKE_CURRENT_SOURCE_DIR}/include
        )
    endif()
    target_link_libraries(${target} PRIVATE scratchbird_client)
endforeach()

if (TARGET sb_verify)
    target_sources(sb_verify PRIVATE crc32c.cpp)
endif()

 
