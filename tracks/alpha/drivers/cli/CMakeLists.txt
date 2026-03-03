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

set(SB_CPP_DRIVER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../beta/drivers/cpp")
if (NOT TARGET scratchbird_client)
    add_subdirectory("${SB_CPP_DRIVER_DIR}" "${CMAKE_BINARY_DIR}/scratchbird_cpp")
endif()

add_executable(sb_isql
    sb_isql.cpp
    metadata_shaping.cpp
)
add_executable(sb_admin sb_admin.cpp)
add_executable(sb_backup sb_backup.cpp)
add_executable(sb_security sb_security.cpp)
add_executable(sb_verify sb_verify.cpp)
add_executable(sbdriver_conformance
    sbdriver_conformance.cpp
    txn_exec_parity.cpp
)

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
    set(fdw_basic_cli_targets sb_pg_isql sb_my_isql)
    set(SB_ENGINE_INCLUDE_DIR "${SB_ENGINE_SOURCE_DIR}/include")
    set(SB_ENGINE_LIB_DIR "${SB_ENGINE_BUILD_DIR}/src")
    set(SB_ENGINE_FDW_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_fdw.a")
    set(SB_ENGINE_SBLR_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_sblr.a")
    set(SB_ENGINE_PARSER_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_parser.a")
    set(SB_ENGINE_COMPILER_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_compiler.a")
    set(SB_ENGINE_CORE_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_core.a")
    set(SB_ENGINE_OPTIMIZER_RUNTIME_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_optimizer_runtime.a")
    set(SB_ENGINE_OPTIMIZER_COMPILER_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_optimizer_compiler.a")
    set(SB_ENGINE_SECURITY_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_security.a")
    set(SB_ENGINE_IPC_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_ipc.a")
    set(SB_ENGINE_UDR_LIB "${SB_ENGINE_LIB_DIR}/libscratchbird_udr.a")

    set(sb_engine_libs_ready TRUE)
    foreach(required_path IN LISTS
            SB_ENGINE_FDW_LIB
            SB_ENGINE_SBLR_LIB
            SB_ENGINE_PARSER_LIB
            SB_ENGINE_COMPILER_LIB
            SB_ENGINE_CORE_LIB
            SB_ENGINE_OPTIMIZER_RUNTIME_LIB
            SB_ENGINE_SECURITY_LIB
            SB_ENGINE_IPC_LIB
            SB_ENGINE_UDR_LIB)
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

    set(SB_FB_LINK_ARCHIVES
        "${SB_ENGINE_COMPILER_LIB}"
        "${SB_ENGINE_PARSER_LIB}"
        "${SB_ENGINE_SBLR_LIB}"
        "${SB_ENGINE_CORE_LIB}"
        "${SB_ENGINE_OPTIMIZER_RUNTIME_LIB}"
        "${SB_ENGINE_SECURITY_LIB}"
        "${SB_ENGINE_IPC_LIB}"
        "${SB_ENGINE_UDR_LIB}"
    )
    if (EXISTS "${SB_ENGINE_OPTIMIZER_COMPILER_LIB}")
        list(APPEND SB_FB_LINK_ARCHIVES "${SB_ENGINE_OPTIMIZER_COMPILER_LIB}")
    endif()

    find_package(OpenSSL REQUIRED)
    find_package(Threads REQUIRED)
    find_package(LibXml2 REQUIRED)
    find_package(ZLIB REQUIRED)
    find_package(GEOS QUIET)
    find_package(PROJ QUIET)
    find_package(PkgConfig QUIET)
    if (PkgConfig_FOUND)
        pkg_check_modules(LZ4 QUIET liblz4)
        pkg_check_modules(ZSTD QUIET libzstd)
    endif()
    find_library(CRYPT_LIBRARY crypt)
    find_library(GEOS_C_LIBRARY NAMES geos_c)

    foreach(target IN LISTS fdw_basic_cli_targets)
        target_include_directories(${target} BEFORE PRIVATE "${SB_ENGINE_INCLUDE_DIR}")
        target_link_libraries(${target}
            PRIVATE
                "${SB_ENGINE_FDW_LIB}"
                "${SB_ENGINE_SBLR_LIB}"
                "${SB_ENGINE_PARSER_LIB}"
                "${SB_ENGINE_CORE_LIB}"
                "${SB_ENGINE_UDR_LIB}"
                OpenSSL::SSL
                OpenSSL::Crypto
                Threads::Threads
        )
    endforeach()

    target_include_directories(sb_fb_isql BEFORE PRIVATE "${SB_ENGINE_INCLUDE_DIR}")
    if (CMAKE_CXX_LINK_GROUP_USING_RESCAN_SUPPORTED)
        string(JOIN "," SB_FB_LINK_ARCHIVES_CSV ${SB_FB_LINK_ARCHIVES})
        target_link_libraries(sb_fb_isql PRIVATE "$<LINK_GROUP:RESCAN,${SB_FB_LINK_ARCHIVES_CSV}>")
    elseif(UNIX AND NOT APPLE)
        target_link_libraries(sb_fb_isql
            PRIVATE
                -Wl,--start-group
                ${SB_FB_LINK_ARCHIVES}
                -Wl,--end-group
        )
    else()
        target_link_libraries(sb_fb_isql PRIVATE ${SB_FB_LINK_ARCHIVES})
    endif()

    set(SB_FB_EXTERNAL_LIBS
        "${SB_ENGINE_FDW_LIB}"
        LibXml2::LibXml2
        ZLIB::ZLIB
        OpenSSL::SSL
        OpenSSL::Crypto
        Threads::Threads
    )
    if (GEOS_C_LIBRARY)
        list(APPEND SB_FB_EXTERNAL_LIBS "${GEOS_C_LIBRARY}")
    elseif (GEOS_FOUND)
        list(APPEND SB_FB_EXTERNAL_LIBS ${GEOS_LIBRARIES})
    else()
        list(APPEND SB_FB_EXTERNAL_LIBS geos_c)
    endif()
    if (PROJ_FOUND)
        list(APPEND SB_FB_EXTERNAL_LIBS ${PROJ_LIBRARIES})
    else()
        list(APPEND SB_FB_EXTERNAL_LIBS proj)
    endif()
    if (LZ4_FOUND)
        target_link_directories(sb_fb_isql PRIVATE ${LZ4_LIBRARY_DIRS})
        target_compile_options(sb_fb_isql PRIVATE ${LZ4_CFLAGS_OTHER})
        list(APPEND SB_FB_EXTERNAL_LIBS ${LZ4_LIBRARIES})
    else()
        list(APPEND SB_FB_EXTERNAL_LIBS lz4)
    endif()
    if (ZSTD_FOUND)
        target_link_directories(sb_fb_isql PRIVATE ${ZSTD_LIBRARY_DIRS})
        target_compile_options(sb_fb_isql PRIVATE ${ZSTD_CFLAGS_OTHER})
        list(APPEND SB_FB_EXTERNAL_LIBS ${ZSTD_LIBRARIES})
    else()
        list(APPEND SB_FB_EXTERNAL_LIBS zstd)
    endif()
    if (CRYPT_LIBRARY)
        list(APPEND SB_FB_EXTERNAL_LIBS "${CRYPT_LIBRARY}")
    endif()
    if (UNIX AND NOT APPLE)
        list(APPEND SB_FB_EXTERNAL_LIBS dl m)
    endif()
    target_link_libraries(sb_fb_isql PRIVATE ${SB_FB_EXTERNAL_LIBS})
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

add_executable(sbdriver_txn_exec_tests
    txn_exec_parity_test.cpp
    txn_exec_parity.cpp
)
target_include_directories(sbdriver_txn_exec_tests
    PRIVATE
        "${SB_CPP_DRIVER_DIR}/include"
)
target_link_libraries(sbdriver_txn_exec_tests PRIVATE scratchbird_client)

add_executable(sbdriver_metadata_shaping_tests
    metadata_shaping_test.cpp
    metadata_shaping.cpp
)
