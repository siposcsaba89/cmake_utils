# Example 8: Application with Third-Party Dependencies
# This example shows how to create an executable with external package dependencies

cmake_minimum_required(VERSION 3.20)
project(application_with_thirdparty_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# Create an application that uses third-party libraries
cu_add_application(render_app
    NAMESPACE graphics
    SRCS
        src/main.cpp
        src/window.cpp
        src/renderer.cpp
        src/shader_manager.cpp
    THIRDPARTY_PRIVATE_DEPS
        # OpenGL example
        "OpenGL+OpenGL::GL"
        # GLFW example
        "glfw3+glfw"
        # GLM example (header-only math library)
        "glm+glm::glm"
        # Example with multiple targets from same package
        "Vulkan+Vulkan::Vulkan|Vulkan::shaderc_combined"
    PRIVATE_DEFS
        GLFW_INCLUDE_NONE
        APP_NAME="RenderApp"
    PRIVATE_COMPILE_OPTIONS
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
        $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -pedantic>
    FOLDER "Applications/Graphics"
)

# Third-party dependencies work the same as with cu_add_library
# - Use "Package+Target1|Target2" syntax
# - find_package() is called automatically
# - Multiple targets from the same package separated by '|'
