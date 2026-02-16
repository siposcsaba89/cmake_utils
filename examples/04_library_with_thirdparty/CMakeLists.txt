# Example 4: Library with Third-Party Dependencies
# This example shows how to use external packages with the strict Pkg+Target syntax

cmake_minimum_required(VERSION 3.20)
project(library_with_thirdparty_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create a library that depends on third-party packages
cu_add_library(data_processor
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/data_processor/json_parser.h
        include/myapp/data_processor/xml_parser.h
        include/myapp/data_processor/logger.h
    SRCS
        src/json_parser.cpp
        src/xml_parser.cpp
        src/logger.cpp
    # Third-party dependencies using the strict "Package+Target1|Target2" syntax
    THIRDPARTY_PUBLIC_DEPS
        # Example: nlohmann_json package with its target
        "nlohmann_json+nlohmann_json::nlohmann_json"
        # Example: fmt package with its target
        "fmt+fmt::fmt"
    THIRDPARTY_PRIVATE_DEPS
        # Example: spdlog package (private, not exposed in public API)
        "spdlog+spdlog::spdlog"
        # Example: Boost with multiple targets using | separator
        "Boost+Boost::filesystem|Boost::system"
    PUBLIC_DEPS
        # Internal library dependencies (if you have other cu_add_library targets)
        myapp::common
    FOLDER "DataProcessing"
)

# Third-party dependency syntax:
# Format: "PackageName+Target1|Target2|Target3"
# - Left side of '+' is passed to find_package()
# - Right side lists targets to link, separated by '|'
# - Targets can be Pkg::Target or plain names if already defined
# - Each dependency string can have multiple targets after '+'
