# Example 2: Shared Library with Compile Definitions
# This example shows how to create a shared library with public and private compile definitions

cmake_minimum_required(VERSION 3.20)
project(shared_library_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create a shared library with compile definitions
cu_add_library(graphics_engine
    NAMESPACE graphics
    SHARED
    PUBLIC_HEADERS
        include/graphics/graphics_engine/renderer.h
        include/graphics/graphics_engine/shader.h
        include/graphics/graphics_engine/texture.h
    SRCS
        src/renderer.cpp
        src/shader.cpp
        src/texture.cpp
        src/internal_helpers.cpp
    PUBLIC_DEFS
        GRAPHICS_ENGINE_VERSION_MAJOR=1
        GRAPHICS_ENGINE_VERSION_MINOR=0
    PRIVATE_DEFS
        GRAPHICS_ENGINE_INTERNAL_BUILD
        ENABLE_LOGGING
    FOLDER "Graphics"
)

# The SHARED option creates a dynamic library with:
# - Hidden symbol visibility by default
# - Export headers for proper DLL exports
# - Platform-specific extensions (.so, .dll, .dylib)
