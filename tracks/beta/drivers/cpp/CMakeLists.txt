cmake_minimum_required(VERSION 3.20)
project(scratchbird_client VERSION 0.1.0 LANGUAGES C CXX)

add_library(scratchbird_client
    src/connection.cpp
    src/circuit_breaker.cpp
    src/keepalive.cpp
    src/leak_detector.cpp
    src/telemetry.cpp
    src/statement_cache.cpp
    src/driver_config.cpp
    src/network_client.cpp
    src/protocol/sbwp_protocol.cpp
    src/scratchbird_client_c.cpp
    src/core/sqlstate.cpp
    src/core/type_extractor.cpp
    src/network/network.cpp
    src/network/socket.cpp
    src/network/socket_types.cpp
    src/security/tls_context.cpp
)

set_target_properties(scratchbird_client PROPERTIES POSITION_INDEPENDENT_CODE ON)

target_include_directories(scratchbird_client
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(scratchbird_client PUBLIC cxx_std_17)

find_package(OpenSSL REQUIRED)
target_link_libraries(scratchbird_client PRIVATE OpenSSL::SSL OpenSSL::Crypto)

if (WIN32)
    target_link_libraries(scratchbird_client PRIVATE ws2_32)
endif()

include(CTest)
if (BUILD_TESTING)
    target_compile_definitions(scratchbird_client PRIVATE SCRATCHBIRD_TEST_HOOKS)

    find_package(GTest)
    if (GTest_FOUND)
        add_executable(scratchbird_client_tests
            tests/test_driver_connectivity.cpp
            tests/test_driver_defaults.cpp
            tests/test_type_mapping.cpp
            tests/test_paging_payload.cpp
        )
        target_link_libraries(scratchbird_client_tests
            PRIVATE
                scratchbird_client
                GTest::gtest
                GTest::gtest_main
        )
        add_test(NAME scratchbird_client_tests COMMAND scratchbird_client_tests)
    endif()
endif()
