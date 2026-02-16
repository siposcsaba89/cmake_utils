# Example 7: Application with Library Dependencies
# This example shows how to create an executable that links against libraries

cmake_minimum_required(VERSION 3.20)
project(application_with_deps_example VERSION 1.0.0)

include(../../cu_add_library.cmake)

# First, create a library
cu_add_library(game_engine
    NAMESPACE game
    STATIC
    PUBLIC_HEADERS
        include/game/game_engine/engine.h
        include/game/game_engine/scene.h
    SRCS
        src/engine.cpp
        src/scene.cpp
)

# Then create an application that uses the library
cu_add_application(game_launcher
    NAMESPACE game
    SRCS
        src/main.cpp
        src/game_config.cpp
    PRIVATE_DEPS
        # Link against the library created above
        game::game_engine
    PRIVATE_DEFS
        GAME_DATA_PATH="${CMAKE_SOURCE_DIR}/assets"
    RPATH
        # Additional runtime library search paths
        game_modules
    FOLDER "Applications/Game"
)

# Key features:
# - PRIVATE_DEPS links the library but doesn't export it (executables don't export)
# - RPATH sets runtime library search paths
# - The game_engine library will be found automatically via its alias
