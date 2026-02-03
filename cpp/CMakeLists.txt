add_library(scratchbird_client
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
