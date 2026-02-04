add_library(scratchbird_odbc SHARED
    src/odbc_client_bridge.cpp
    src/odbc_driver.cpp
    src/odbc_handles.cpp
)

if (NOT TARGET scratchbird_client)
    add_subdirectory(
        ${CMAKE_CURRENT_LIST_DIR}/../../../beta/drivers/cpp
        ${CMAKE_CURRENT_BINARY_DIR}/scratchbird_cpp
    )
endif()

target_include_directories(scratchbird_odbc
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_LIST_DIR}/../../../beta/drivers/cpp/include
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
