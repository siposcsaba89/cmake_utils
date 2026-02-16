# Example 3: Header-Only (Interface) Library
# This example shows how to create a header-only library

cmake_minimum_required(VERSION 3.20)
project(interface_library_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create a header-only library
cu_add_library(math_templates
    NAMESPACE utils
    INTERFACE
    PUBLIC_HEADERS
        include/utils/math_templates/vector.h
        include/utils/math_templates/matrix.h
        include/utils/math_templates/quaternion.h
    PUBLIC_COMPILE_OPTIONS
        $<$<CXX_COMPILER_ID:MSVC>:/permissive->
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
)

# Interface libraries:
# - Contain only header files (no SRCS)
# - All properties are INTERFACE (propagated to consumers)
# - No compiled binary is generated
# - Perfect for template-heavy code
