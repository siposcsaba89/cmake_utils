# Example 6: Simple Application (Executable)
# This example shows how to create a basic executable using cu_add_application

cmake_minimum_required(VERSION 3.20)
project(simple_application_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create a simple executable
cu_add_application(my_app
    NAMESPACE mycompany
    SRCS
        src/main.cpp
        src/app_logic.cpp
        src/cli_parser.cpp
    PRIVATE_DEFS
        APP_VERSION="1.0.0"
        ENABLE_DEBUG_OUTPUT
    FOLDER "Applications"
)

# The above creates:
# - An executable target named "my_app"
# - Debug/Release postfixes (_d, _rd, _mr)
# - Install rules to bin/ directory
# - Platform-specific file extensions
