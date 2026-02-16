# CMake Utils Examples

This directory contains comprehensive examples demonstrating how to use the `cu_add_library` and `cu_add_application` macros from the cmake_utils package.

## Overview

The cmake_utils package provides three main macros:
- **`cu_add_library`** - Create libraries (static, shared, or header-only)
- **`cu_add_application`** - Create executables/applications
- **`cu_add_test`** - Create test executables with Google Test integration

These macros provide a unified, high-level interface for creating targets with sensible defaults and automatic handling of:
- Source organization and grouping
- Namespace aliasing
- Installation rules
- Export headers (for shared libraries)
- Third-party package dependencies
- Compile options and definitions
- RPATH configuration

## Examples Index

### Library Examples

1. **[01_simple_library](01_simple_library/)** - Basic static library with headers and sources
2. **[02_shared_library](02_shared_library/)** - Shared library with compile definitions
3. **[03_interface_library](03_interface_library/)** - Header-only library with compile options
4. **[04_library_with_thirdparty](04_library_with_thirdparty/)** - Library with external package dependencies
5. **[05_library_with_internal_deps](05_library_with_internal_deps/)** - Libraries depending on other project libraries

### Application Examples

6. **[06_simple_application](06_simple_application/)** - Basic executable
7. **[07_application_with_deps](07_application_with_deps/)** - Executable linking project libraries
8. **[08_application_with_thirdparty](08_application_with_thirdparty/)** - Executable with third-party dependencies
9. **[09_advanced_application](09_advanced_application/)** - Advanced configuration with compile options and RPATH

### Advanced Examples

10. **[10_custom_target_properties](10_custom_target_properties/)** - Using TARGET_PROPERTIES for custom configurations

## cu_add_library Reference

### Syntax
```cmake
cu_add_library(<LibraryName>
    [STATIC | SHARED | INTERFACE]
    [NAMESPACE <namespace>]
    [FOLDER <IDE_folder>]
    [PUBLIC_HEADERS <headers...>]
    [SRCS <sources...>]
    [PUBLIC_DEPS <targets...>]
    [PRIVATE_DEPS <targets...>]
    [PUBLIC_DEFS <definitions...>]
    [PRIVATE_DEFS <definitions...>]
    [PUBLIC_COMPILE_OPTIONS <options...>]
    [PRIVATE_COMPILE_OPTIONS <options...>]
    [THIRDPARTY_PUBLIC_DEPS <pkg_specs...>]
    [THIRDPARTY_PRIVATE_DEPS <pkg_specs...>]
    [RPATH <paths...>]
    [TARGET_PROPERTIES <properties...>]
)
```

### Parameters

#### Library Type (mutually exclusive)
- `STATIC` - Creates a static library (.lib/.a)
- `SHARED` - Creates a shared library (.dll/.so/.dylib) with export headers
- `INTERFACE` - Creates a header-only library (no compiled code)
- If none specified, uses CMake's default (BUILD_SHARED_LIBS)

#### Basic Configuration
- `NAMESPACE` - Namespace for the library alias (creates `namespace::basename` alias)
- `FOLDER` - IDE folder for organizing targets in Visual Studio/Xcode
- `PUBLIC_HEADERS` - List of public header files (installed)
- `SRCS` - List of source files (.cpp, .c, etc.)

#### Dependencies
- `PUBLIC_DEPS` - Internal library dependencies (propagated to consumers)
- `PRIVATE_DEPS` - Internal library dependencies (not propagated)
- `THIRDPARTY_PUBLIC_DEPS` - External package dependencies (propagated)
- `THIRDPARTY_PRIVATE_DEPS` - External package dependencies (not propagated)

**Third-Party Dependency Syntax:**
```cmake
"PackageName+Target1|Target2|Target3"
```
- Left of `+` is the package name for `find_package()`
- Right of `+` lists targets to link, separated by `|`
- Example: `"Boost+Boost::filesystem|Boost::system"`

#### Compile Settings
- `PUBLIC_DEFS` - Preprocessor definitions for library and consumers
- `PRIVATE_DEFS` - Preprocessor definitions for library only
- `PUBLIC_COMPILE_OPTIONS` - Compile flags for library and consumers
- `PRIVATE_COMPILE_OPTIONS` - Compile flags for library only

#### Runtime Configuration
- `RPATH` - Additional runtime library search paths
- `TARGET_PROPERTIES` - Custom target properties (property-value pairs)

### Features

The macro automatically handles:
- Creates an alias: `${NAMESPACE}::${BASENAME}`
- Directory layout: `include/${NAMESPACE}/${BASENAME}/`
- C++20 standard requirement
- Debug/Release postfixes (_d, _rd, _mr)
- Multi-processor compilation on MSVC (/MP)
- Symbol visibility (hidden by default for shared libs)
- Export header generation for shared libraries
- Install rules for headers, libraries, and CMake config files
- Package config and version files
- Source grouping in IDEs
- RPATH settings for runtime library discovery

## cu_add_application Reference

### Syntax
```cmake
cu_add_application(<ApplicationName>
    [NAMESPACE <namespace>]
    [FOLDER <IDE_folder>]
    [SRCS <sources...>]
    [PUBLIC_DEPS <targets...>]
    [PRIVATE_DEPS <targets...>]
    [PUBLIC_DEFS <definitions...>]
    [PRIVATE_DEFS <definitions...>]
    [PUBLIC_COMPILE_OPTIONS <options...>]
    [PRIVATE_COMPILE_OPTIONS <options...>]
    [THIRDPARTY_PUBLIC_DEPS <pkg_specs...>]
    [THIRDPARTY_PRIVATE_DEPS <pkg_specs...>]
    [RPATH <paths...>]
    [WORKING_DIRECTORY <path>]
    [TARGET_PROPERTIES <properties...>]
)
```

### Parameters

Most parameters are identical to `cu_add_library`:

- `NAMESPACE` - Namespace for organizing the application
- `FOLDER` - IDE folder for organizing targets
- `SRCS` - List of source files
- `PUBLIC_DEPS` / `PRIVATE_DEPS` - Internal library dependencies
- `THIRDPARTY_PUBLIC_DEPS` / `THIRDPARTY_PRIVATE_DEPS` - External dependencies
- `PUBLIC_DEFS` / `PRIVATE_DEFS` - Compile definitions
- `PUBLIC_COMPILE_OPTIONS` / `PRIVATE_COMPILE_OPTIONS` - Compile flags
- `RPATH` - Runtime library search paths
- `WORKING_DIRECTORY` - Working directory for the executable (rarely needed)
- `TARGET_PROPERTIES` - Custom target properties (property-value pairs)

### Features

The macro automatically handles:
- Creates executable with proper naming
- C++20 standard requirement
- Debug/Release postfixes (_d, _rd, _mr)
- Multi-processor compilation on MSVC (/MP)
- Install rules to bin/ directory
- RPATH settings for finding shared libraries
- Source grouping in IDEs

## Common Patterns

### 1. Simple Library
```cmake
cu_add_library(mylib
    NAMESPACE mycompany
    STATIC
    PUBLIC_HEADERS
        include/mycompany/mylib/api.h
    SRCS
        src/api.cpp
)
```

### 2. Library with External Dependencies
```cmake
cu_add_library(datalib
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS
        include/myapp/datalib/parser.h
    SRCS
        src/parser.cpp
    THIRDPARTY_PUBLIC_DEPS
        "nlohmann_json+nlohmann_json::nlohmann_json"
    THIRDPARTY_PRIVATE_DEPS
        "Boost+Boost::filesystem"
)
```

### 3. Application Using Libraries
```cmake
cu_add_library(mylib NAMESPACE myapp STATIC ...)

cu_add_application(myapp
    NAMESPACE myapp
    SRCS src/main.cpp
    PRIVATE_DEPS myapp::mylib
)
```

### 4. Header-Only Library
```cmake
cu_add_library(templates
    NAMESPACE utils
    INTERFACE
    PUBLIC_HEADERS
        include/utils/templates/vector.h
)
```

### 5. Custom Target Properties
```cmake
cu_add_library(custom_lib
    NAMESPACE myapp
    STATIC
    PUBLIC_HEADERS include/api.h
    SRCS src/api.cpp
    TARGET_PROPERTIES
        # Override C++ standard
        CXX_STANDARD 17
        # Custom output name
        OUTPUT_NAME "custom_api"
        # Enable IPO for release builds
        INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
        # Custom output directory
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/libs"
)
```

## TARGET_PROPERTIES Parameter

The `TARGET_PROPERTIES` parameter allows you to set custom CMake target properties that are not directly exposed by `cu_add_library` or `cu_add_application`. This provides full flexibility while maintaining the convenience of the high-level macros.

### Usage

Pass property-value pairs as a list:

```cmake
TARGET_PROPERTIES
    PROPERTY_NAME value
    ANOTHER_PROPERTY "value with spaces"
    NUMERIC_PROPERTY 42
```

### Common Use Cases

**1. Language Standards**
```cmake
TARGET_PROPERTIES
    CXX_STANDARD 17              # Override default C++20
    CXX_STANDARD_REQUIRED TRUE
    CXX_EXTENSIONS OFF           # Disable compiler extensions
```

**2. CUDA Configuration**
```cmake
TARGET_PROPERTIES
    CUDA_ARCHITECTURES "75;86;89"
    CUDA_SEPARABLE_COMPILATION ON
```

**3. Output Configuration**
```cmake
TARGET_PROPERTIES
    OUTPUT_NAME "custom_name"
    PREFIX "lib"
    SUFFIX ".ext"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
```

**4. Optimization**
```cmake
TARGET_PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
    INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO TRUE
```

**5. Platform-Specific**
```cmake
TARGET_PROPERTIES
    WIN32_EXECUTABLE TRUE        # Windows GUI app
    MACOSX_BUNDLE TRUE          # macOS app bundle
    POSITION_INDEPENDENT_CODE ON # PIC/PIE
```

**6. IDE/Debugger Settings**
```cmake
TARGET_PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    VS_DEBUGGER_COMMAND_ARGUMENTS "--help"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "TeamID"
```

**7. Versioning**
```cmake
TARGET_PROPERTIES
    VERSION 2.1.0
    SOVERSION 2
```

### Important Notes

- `TARGET_PROPERTIES` are applied **after** the default properties set by the macros
- You can **override** default properties (e.g., changing CXX_STANDARD from 20 to 17)
- All standard CMake [target properties](https://cmake.org/cmake/help/latest/manual/cmake-properties.7.html#target-properties) are supported
- Properties are passed directly to `set_target_properties()`

## Best Practices

1. **Use NAMESPACE consistently** - Helps organize large projects
2. **Separate PUBLIC and PRIVATE deps** - PUBLIC only when types appear in public API
3. **Use strict third-party syntax** - Always use `"Pkg+Target"` format
4. **Leverage FOLDER** - Improves IDE organization
5. **Use generator expressions** - For config-specific settings
   ```cmake
   PRIVATE_DEFS
       $<$<CONFIG:Debug>:ENABLE_LOGGING>
   ```
6. **INTERFACE for templates** - Use INTERFACE libraries for header-only code
7. **RPATH for plugins** - Set RPATH when using plugin architectures
8. **TARGET_PROPERTIES for special cases** - Use when you need properties not directly exposed by the macros

## Project Structure

Expected directory structure for libraries:
```
my_library/
├── CMakeLists.txt
├── include/
│   └── namespace/
│       └── library_name/
│           └── header.h
└── src/
    └── implementation.cpp
```

Expected directory structure for applications:
```
my_application/
├── CMakeLists.txt
└── src/
    ├── main.cpp
    └── other_sources.cpp
```

## Additional Notes

### Versioning
- All targets use the project version from `CMAKE_PROJECT_VERSION`
- Debug builds get `_d` suffix, RelWithDebInfo get `_rd`, MinSizeRel get `_mr`

### Installation
Libraries install to:
- Headers: `include/${namespace}/${basename}/`
- Libraries: `lib/`
- CMake configs: `share/${library_name}/`

Applications install to:
- Executables: `bin/`

### Cross-Platform Support
- Automatically handles platform-specific library extensions
- RPATH configured for Linux/macOS (@rpath)
- Export headers for Windows DLL visibility

## See Also

- [cu_add_library.cmake](../cu_add_library.cmake) - Full implementation
- [cu_add_test](../cu_add_library.cmake#L371) - For creating test executables
