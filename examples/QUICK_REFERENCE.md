# Quick Reference: cu_add_library & cu_add_application

## cu_add_library - Quick Examples

### Static Library
```cmake
cu_add_library(mylib
    NAMESPACE mycompany    # Creates alias: mycompany::mylib
    STATIC                 # Static library
    PUBLIC_HEADERS
        include/mycompany/mylib/api.h
    SRCS
        src/api.cpp
    FOLDER "Libraries"
)
```

### Shared Library
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    SHARED                 # Dynamic library with export headers
    PUBLIC_HEADERS
        include/mycompany/mylib/api.h
    SRCS
        src/api.cpp
)
```

### Header-Only Library
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    INTERFACE              # No SRCS needed
    PUBLIC_HEADERS
        include/mycompany/mylib/templates.h
)
```

### With Third-Party Dependencies
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    STATIC
    PUBLIC_HEADERS include/api.h
    SRCS src/api.cpp
    THIRDPARTY_PUBLIC_DEPS
        "fmt+fmt::fmt"                           # Single target
        "Boost+Boost::filesystem|Boost::system"  # Multiple targets
    THIRDPARTY_PRIVATE_DEPS
        "spdlog+spdlog::spdlog"
)
```

### With Internal Dependencies
```cmake
cu_add_library(base NAMESPACE myapp STATIC ...)
cu_add_library(derived
    NAMESPACE myapp
    STATIC
    PUBLIC_DEPS myapp::base    # Use namespace alias
    ...
)
```

### With Compile Definitions & Options
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    STATIC
    PUBLIC_HEADERS include/api.h
    SRCS src/api.cpp
    PUBLIC_DEFS
        MYLIB_VERSION=1
    PRIVATE_DEFS
        $<$<CONFIG:Debug>:ENABLE_DEBUG_LOGGING>
    PRIVATE_COMPILE_OPTIONS
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
        $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra>
)
```

### With Custom Target Properties
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    STATIC
    PUBLIC_HEADERS include/api.h
    SRCS src/api.cpp
    TARGET_PROPERTIES
        CXX_STANDARD 17
        OUTPUT_NAME "custom_api"
        INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
)
```

## cu_add_application - Quick Examples

### Simple Executable
```cmake
cu_add_application(myapp
    NAMESPACE mycompany
    SRCS
        src/main.cpp
        src/app_logic.cpp
    FOLDER "Applications"
)
```

### With Library Dependencies
```cmake
cu_add_library(mylib NAMESPACE myapp STATIC ...)

cu_add_application(myapp
    NAMESPACE myapp
    SRCS src/main.cpp
    PRIVATE_DEPS
        myapp::mylib       # Link project library
)
```

### With Third-Party Dependencies
```cmake
cu_add_application(myapp
    NAMESPACE myapp
    SRCS src/main.cpp
    THIRDPARTY_PRIVATE_DEPS
        "glfw3+glfw"
        "OpenGL+OpenGL::GL"
        "Vulkan+Vulkan::Vulkan"
)
```

### With Custom Configuration
```cmake
cu_add_application(myapp
    NAMESPACE myapp
    SRCS src/main.cpp
    PRIVATE_DEFS
        APP_VERSION="1.0.0"
        $<$<CONFIG:Release>:OPTIMIZED_BUILD>
    PRIVATE_COMPILE_OPTIONS
        $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>
    RPATH
        plugins
        ../external_libs
    FOLDER "Applications"
)
```

## Parameter Quick Reference

### Common to Both
| Parameter | Description | Example |
|-----------|-------------|---------|
| `NAMESPACE` | Create namespace alias | `NAMESPACE myapp` → `myapp::target` |
| `FOLDER` | IDE organization folder | `FOLDER "Libraries/Core"` |
| `SRCS` | Source files | `SRCS src/a.cpp src/b.cpp` |
| `PUBLIC_DEPS` | Internal dependencies (propagated) | `PUBLIC_DEPS myapp::utils` |
| `PRIVATE_DEPS` | Internal dependencies (not propagated) | `PRIVATE_DEPS myapp::internal` |
| `PUBLIC_DEFS` | Compile definitions (propagated) | `PUBLIC_DEFS MY_API_VERSION=2` |
| `PRIVATE_DEFS` | Compile definitions (not propagated) | `PRIVATE_DEFS INTERNAL_DEBUG` |
| `PUBLIC_COMPILE_OPTIONS` | Compile flags (propagated) | See examples above |
| `PRIVATE_COMPILE_OPTIONS` | Compile flags (not propagated) | See examples above |
| `THIRDPARTY_PUBLIC_DEPS` | External deps (propagated) | `"Pkg+Pkg::Target"` |
| `THIRDPARTY_PRIVATE_DEPS` | External deps (not propagated) | `"Pkg+Pkg::Target"` |
| `RPATH` | Runtime library search paths | `RPATH plugins lib` |
| `TARGET_PROPERTIES` | Custom target properties | `TARGET_PROPERTIES CXX_STANDARD 17` |

### Library-Specific
| Parameter | Description | Example |
|-----------|-------------|---------|
| `STATIC` | Create static library | `STATIC` |
| `SHARED` | Create shared library | `SHARED` |
| `INTERFACE` | Create header-only library | `INTERFACE` |
| `PUBLIC_HEADERS` | Public header files | `PUBLIC_HEADERS include/api.h` |

### Application-Specific
| Parameter | Description | Example |
|-----------|-------------|---------|
| `WORKING_DIRECTORY` | Execution working directory | `WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/data` |

## Third-Party Dependency Syntax

**Format:** `"PackageName+Target1|Target2|Target3"`

- **Left of `+`**: Package name for `find_package()`
- **Right of `+`**: Targets to link (separated by `|`)

**Examples:**
```cmake
"fmt+fmt::fmt"                               # Single target
"Boost+Boost::filesystem|Boost::system"      # Multiple targets
"Vulkan+Vulkan::Vulkan|Vulkan::shaderc_combined"  # Multiple Vulkan targets
```

## Common Generator Expressions

```cmake
# Config-specific definitions
$<$<CONFIG:Debug>:ENABLE_DEBUG>
$<$<CONFIG:Release>:OPTIMIZED>

# Compiler-specific options
$<$<CXX_COMPILER_ID:MSVC>:/W4>
$<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra>
$<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra>

# Platform-specific
$<$<PLATFORM_ID:Windows>:WINDOWS_BUILD>
$<$<PLATFORM_ID:Linux>:LINUX_BUILD>

# Combined conditions
$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/permissive->
```

## TARGET_PROPERTIES Examples

```cmake
# Language standards
TARGET_PROPERTIES
    CXX_STANDARD 17              # Override default C++20
    CXX_STANDARD_REQUIRED TRUE
    CXX_EXTENSIONS OFF

# CUDA configuration
TARGET_PROPERTIES
    CUDA_ARCHITECTURES "75;86;89"
    CUDA_SEPARABLE_COMPILATION ON

# Output naming and location
TARGET_PROPERTIES
    OUTPUT_NAME "custom_name"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/libs"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"

# Optimization
TARGET_PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
    POSITION_INDEPENDENT_CODE ON

# Platform-specific executables
TARGET_PROPERTIES
    WIN32_EXECUTABLE TRUE        # Windows GUI app
    MACOSX_BUNDLE TRUE          # macOS bundle

# IDE/Debugger settings
TARGET_PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    VS_DEBUGGER_COMMAND_ARGUMENTS "--config debug.json"

# Versioning (shared libraries)
TARGET_PROPERTIES
    VERSION 2.1.0
    SOVERSION 2
```

## Typical Project Structure

```
project/
├── CMakeLists.txt                  # Top-level
├── libs/
│   ├── core/
│   │   ├── CMakeLists.txt          # cu_add_library(core ...)
│   │   ├── include/
│   │   │   └── myapp/
│   │   │       └── core/
│   │   │           └── *.h
│   │   └── src/
│   │       └── *.cpp
│   └── utils/
│       ├── CMakeLists.txt          # cu_add_library(utils ...)
│       └── ...
└── apps/
    ├── main_app/
    │   ├── CMakeLists.txt          # cu_add_application(main_app ...)
    │   └── src/
    │       └── main.cpp
    └── tool/
        └── ...
```

## Key Points

✅ **DO:**
- Use `NAMESPACE` for better organization
- Separate `PUBLIC` and `PRIVATE` dependencies appropriately
- Use the `"Pkg+Target"` syntax for third-party deps
- Use generator expressions for conditionals
- Organize with `FOLDER` in multi-target projects
- Use `TARGET_PROPERTIES` for custom configurations (C++ standard, CUDA archs, etc.)

❌ **DON'T:**
- Mix old colon syntax in third-party deps
- Make everything `PUBLIC` (only what's in public API)
- Forget the `+` separator in third-party deps
- Omit NAMESPACE in multi-library projects
