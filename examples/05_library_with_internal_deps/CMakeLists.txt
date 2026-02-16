# Example 5: Library with Internal Dependencies
# This example shows how to create libraries that depend on other project libraries

cmake_minimum_required(VERSION 3.20)
project(library_with_internal_deps_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# First, create a base utility library
cu_add_library(core_utils
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/core_utils/types.h
        include/myapp/core_utils/allocator.h
    SRCS
        src/types.cpp
        src/allocator.cpp
    FOLDER "Libraries/Core"
)

# Then create a library that depends on the first one
cu_add_library(advanced_utils
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/advanced_utils/container.h
        include/myapp/advanced_utils/algorithm.h
    SRCS
        src/container.cpp
        src/algorithm.cpp
    PUBLIC_DEPS
        # Use the alias created by cu_add_library
        myapp::core_utils
    PRIVATE_DEFS
        ADVANCED_UTILS_ENABLE_OPTIMIZATION
    FOLDER "Libraries/Advanced"
)

# Key points:
# - PUBLIC_DEPS makes headers visible to consumers of advanced_utils
# - PRIVATE_DEPS would hide the dependency from consumers
# - Use the namespace::name alias for better modularity
