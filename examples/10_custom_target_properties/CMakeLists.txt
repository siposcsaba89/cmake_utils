# Example 10: Using Custom Target Properties
# This example shows how to use the TARGET_PROPERTIES parameter to customize target properties

cmake_minimum_required(VERSION 3.20)
project(custom_target_properties_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Example 1: Library with custom C++ standard and output name
cu_add_library(legacy_lib
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/legacy_lib/api.h
    SRCS
        src/api.cpp
    TARGET_PROPERTIES
        # Override default C++ standard (default is 20)
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED TRUE
        # Custom output name
        OUTPUT_NAME "legacy_api"
        # Custom archive output directory
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/custom_libs"
    FOLDER "Libraries"
)

# Example 2: Library with CUDA architectures
cu_add_library(gpu_compute
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/gpu_compute/kernel.h
    SRCS
        src/kernel.cu
    TARGET_PROPERTIES
        # Specify CUDA architectures
        CUDA_ARCHITECTURES "75;86;89"
        CUDA_SEPARABLE_COMPILATION ON
        # Position independent code
        POSITION_INDEPENDENT_CODE ON
    FOLDER "Libraries/GPU"
)

# Example 3: Application with custom properties
cu_add_application(custom_app
    NAMESPACE myapp
    SRCS
        src/main.cpp
    TARGET_PROPERTIES
        # Win32 application (no console on Windows)
        WIN32_EXECUTABLE TRUE
        # macOS bundle
        MACOSX_BUNDLE TRUE
        # Custom output directory
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/custom"
        # Version info
        VERSION 2.1.0
        SOVERSION 2
    FOLDER "Applications"
)

# Example 4: Library with interprocedural optimization
cu_add_library(optimized_lib
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/optimized_lib/math.h
    SRCS
        src/math.cpp
    TARGET_PROPERTIES
        # Enable LTO/IPO if available
        INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
        INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO TRUE
        # Custom postfix for release builds
        RELEASE_POSTFIX "_opt"
    PRIVATE_COMPILE_OPTIONS
        $<$<CONFIG:Release>:-O3>
    FOLDER "Libraries/Performance"
)

# Example 5: Header-only library with language requirements
cu_add_library(modern_templates
    NAMESPACE myapp
    INTERFACE
    PUBLIC_HEADERS
        include/myapp/modern_templates/concepts.h
        include/myapp/modern_templates/ranges.h
    TARGET_PROPERTIES
        # Require C++23 features
        CXX_STANDARD 23
        CXX_STANDARD_REQUIRED TRUE
        CXX_EXTENSIONS OFF
)

# Example 6: Application with custom debugging properties
cu_add_application(debuggable_app
    NAMESPACE myapp
    SRCS
        src/main.cpp
    TARGET_PROPERTIES
        # Visual Studio debugger settings
        VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/data"
        VS_DEBUGGER_COMMAND_ARGUMENTS "--config debug.json"
        VS_DEBUGGER_ENVIRONMENT "PATH=${CMAKE_BINARY_DIR}/bin;%PATH%"
    PRIVATE_DEFS
        DEBUG_DATA_PATH="${CMAKE_SOURCE_DIR}/data"
    FOLDER "Applications"
)

# Key points about TARGET_PROPERTIES:
# - Accepts a list of property-value pairs
# - Applied AFTER the default properties set by cu_add_*
# - Can override defaults (like CXX_STANDARD)
# - Can add new properties not set by default
# - Follows standard CMake set_target_properties syntax
# - All CMake target properties are supported

# Common properties you might want to customize:
# - CXX_STANDARD, C_STANDARD, CUDA_STANDARD - Language standards
# - OUTPUT_NAME, PREFIX, SUFFIX - Output file naming
# - *_OUTPUT_DIRECTORY - Where to place binaries
# - POSITION_INDEPENDENT_CODE - PIC/PIE
# - INTERPROCEDURAL_OPTIMIZATION - LTO/IPO
# - CUDA_ARCHITECTURES - GPU compute capabilities
# - WIN32_EXECUTABLE, MACOSX_BUNDLE - Platform-specific executables
# - VS_DEBUGGER_* - Visual Studio debugger settings
# - XCODE_* - Xcode-specific settings
# - SOVERSION, VERSION - Shared library versioning
