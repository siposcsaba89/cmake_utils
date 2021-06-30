cmake_minimum_required(VERSION 3.14)

project(cmake_utils)

install(FILES
        cmake_utils-config.cmake
        cu_add_library.cmake
    DESTINATION lib/cmake/${PROJECT_NAME})