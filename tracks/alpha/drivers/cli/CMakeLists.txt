cmake_minimum_required(VERSION 3.20)

project(scratchbird_cli LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(SB_BUILD_CLI_FDW "Build FDW-backed CLI tools (pg/mysql/firebird)" OFF)

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

 
