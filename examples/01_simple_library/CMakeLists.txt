# Example 1: Simple Static Library
# This example shows how to create a basic static library with public headers and source files

cmake_minimum_required(VERSION 3.20)
project(simple_library_example VERSION 1.0.0)

# Include the cu_add_library macro
include(../../cu_add_library.cmake)

# Create a simple static library
cu_add_library(mylib
    NAMESPACE mycompany
    STATIC
    PUBLIC_HEADERS
        include/mycompany/mylib/math_utils.h
        include/mycompany/mylib/string_utils.h
    SRCS
        src/math_utils.cpp
        src/string_utils.cpp
    FOLDER "Libraries"
)

# The above creates:
# - A library target named "mylib"
# - An alias "mycompany::mylib"
# - Install rules for headers and binaries
# - Export headers with visibility settings
