# Example 9: Application with Compile Options and Custom RPATH
# This example shows advanced features like compile options and runtime paths

cmake_minimum_required(VERSION 3.20)
project(advanced_application_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create an application with advanced configuration
cu_add_application(data_analyzer
    NAMESPACE analytics
    SRCS
        src/main.cpp
        src/analyzer.cpp
        src/data_loader.cpp
        src/reporter.cpp
    THIRDPARTY_PRIVATE_DEPS
        "Threads+Threads::Threads"
        "Boost+Boost::program_options|Boost::filesystem"
    PRIVATE_DEFS
        # Configuration macros
        $<$<CONFIG:Debug>:ANALYTICS_DEBUG_MODE>
        $<$<CONFIG:Release>:ANALYTICS_OPTIMIZED>
        DATA_FORMAT_VERSION=2
    PRIVATE_COMPILE_OPTIONS
        # MSVC specific options
        $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>
        # GCC/Clang specific options
        $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra -Werror -march=native>
        $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -Werror>
    RPATH
        # Custom runtime library paths
        external_libs
        ../plugins
        /opt/analytics/lib
    FOLDER "Applications/Analytics"
)

# Advanced features demonstrated:
# - Generator expressions for config-specific definitions
# - Compiler-specific compile options
# - Custom RPATH for runtime shared library discovery
# - Multiple third-party packages with multiple targets
