add_library(scratchbird_odbc SHARED
    src/odbc_client_bridge.cpp
    src/odbc_driver.cpp
    src/odbc_handles.cpp
)

target_include_directories(scratchbird_odbc
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/cpp/include
)

find_package(ODBC)
if (ODBC_FOUND)
    target_include_directories(scratchbird_odbc PRIVATE ${ODBC_INCLUDE_DIRS})
    target_link_libraries(scratchbird_odbc PRIVATE ${ODBC_LIBRARIES})
endif()

target_link_libraries(scratchbird_odbc PRIVATE scratchbird_client)

if (WIN32)
    target_compile_definitions(scratchbird_odbc PRIVATE NOMINMAX)
endif()
