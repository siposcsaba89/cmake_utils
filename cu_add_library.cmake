#[[
    Common CMake utilities to add libraries, applications, and tests with a unified
    interface and sensible defaults (namespacing, source groups, third-party deps,
    compile options/defs, install rules, etc.).

    Provided macros/functions:
      - cu_add_library(NAME ...)
      - cu_add_application(NAME ...)
      - cu_add_test(NAME ...)
]]

# Helper: compute base name and namespace directory
function(cu__compute_namespace_and_base IN_NAME IN_NAMESPACE OUT_BASE OUT_NAMESPACE_DIR OUT_EFFECTIVE_NAMESPACE)
    set(_name "${IN_NAME}")
    set(_ns   "${IN_NAMESPACE}")
    # Derive BASE_NAME by stripping '<namespace>_' prefix if present
    if(_ns)
        string(REGEX REPLACE "^${_ns}_" "" _base "${_name}")
    else()
        set(_base "${_name}")
    endif()

    set(_ns_dir "${_ns}")
    set(_eff_ns "${_ns}")
    if(NOT _ns)
        set(_ns_dir ".")
        set(_eff_ns "${_name}")
    elseif(_ns STREQUAL _name)
        set(_ns_dir ".")
    endif()

    set(${OUT_BASE} "${_base}" PARENT_SCOPE)
    set(${OUT_NAMESPACE_DIR} "${_ns_dir}" PARENT_SCOPE)
    set(${OUT_EFFECTIVE_NAMESPACE} "${_eff_ns}" PARENT_SCOPE)
endfunction()

# Helper: parse third-party deps list using the new strict syntax only:
#   THIRDPARTY_*_DEPS "Pkg+TargetA|Pkg::TargetB|TargetC"
# Where:
#   - Left side of '+' is the package name to pass to find_package(<Pkg>)
#   - Right side lists CMake targets to link, separated by '|'
#   - Targets can be fully-qualified (e.g., Pkg::Target) or plain if already defined
# Legacy colon-based formats are NOT supported and will error out.
function(cu__collect_thirdparty_targets IN_LIST_VAR OUT_LIST_VAR)
    set(_args_list "${${IN_LIST_VAR}}")
    set(_thirdparty_targets)
    foreach(_arg IN LISTS _args_list)
        if("${_arg}" STREQUAL "")
            # Ignore empty items silently
            continue()
        endif()
        message(STATUS "cu__collect_thirdparty_targets: processing '${_arg}' (strict '+|'-syntax)")
        # Validate that legacy ':' syntax is not used as a package/target separator
        # Allow ':' within target names (e.g., Pkg::Target), which appear AFTER '+'
        string(FIND "${_arg}" "+" _plus_idx)
        string(FIND "${_arg}" ":" _colon_idx)
        if(_colon_idx GREATER -1 AND (_plus_idx EQUAL -1 OR _colon_idx LESS _plus_idx))
            message(FATAL_ERROR "Invalid third-party dep entry '${_arg}'. Only 'Pkg+TargetA|TargetB' syntax is supported.")
        endif()

        string(FIND "${_arg}" "+" _plus_idx)
        if(NOT _plus_idx GREATER -1)
            message(FATAL_ERROR "Invalid third-party dep entry '${_arg}'. Expected 'Pkg+TargetA|TargetB' syntax.")
        endif()

        string(SUBSTRING "${_arg}" 0 ${_plus_idx} _pkg)
        math(EXPR _targets_start "${_plus_idx} + 1")
        string(SUBSTRING "${_arg}" ${_targets_start} -1 _targets_str)

        string(STRIP "${_pkg}" _pkg)
        if("${_pkg}" STREQUAL "")
            message(FATAL_ERROR "Package name missing before '+': '${_arg}'")
        endif()

        # Resolve the package first
        find_package(${_pkg} REQUIRED)

        # Split targets on '|'
        string(REPLACE "|" ";" _targets_list "${_targets_str}")
        set(_any_target FALSE)
        foreach(_tgt IN LISTS _targets_list)
            string(STRIP "${_tgt}" _tgt)
            if("${_tgt}" STREQUAL "")
                continue()
            endif()
            set(_any_target TRUE)
            if(TARGET ${_tgt})
                list(APPEND _thirdparty_targets ${_tgt})
                message(STATUS "  Using third-party target: ${_tgt}")
            else()
                message(FATAL_ERROR "Target '${_tgt}' from package '${_pkg}' not found. Ensure the correct target names after '+', separated by '|'.")
            endif()
        endforeach()
        if(NOT _any_target)
            message(FATAL_ERROR "No targets specified after '+': '${_arg}'. Provide at least one target (e.g., 'Pkg+Pkg::Core').")
        endif()
    endforeach()

    set(${OUT_LIST_VAR} "${_thirdparty_targets}" PARENT_SCOPE)
endfunction()

macro(cu_add_library LIBRARY_NAME)
    set(options OPTIONAL SHARED STATIC INTERFACE)
    set(oneValueArgs RENAME FOLDER NAMESPACE)
    set(multiValueArgs
        PUBLIC_HEADERS 
            SRCS
            PUBLIC_DEPS
            PRIVATE_DEPS
            PUBLIC_DEFS
            PRIVATE_DEFS
            PUBLIC_COMPILE_OPTIONS
            PRIVATE_COMPILE_OPTIONS
            RPATH
            THIRDPARTY_PUBLIC_DEPS
            THIRDPARTY_PRIVATE_DEPS
    )
    cmake_parse_arguments(
        cu #prefix
        "${options}" #options
        "${oneValueArgs}" # one value arguments
        "${multiValueArgs}" # multi value arguments
        ${ARGN}
    )
    

    cu__compute_namespace_and_base(${LIBRARY_NAME} "${cu_NAMESPACE}" BASE_NAME NAMESPACE_DIR cu_NAMESPACE)
#    source_group(${cu_NAMESPACE}\\${BASE_NAME} FILES ${cu_PUBLIC_HEADERS})
#    source_group(src FILES ${cu_SRCS})
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/include FILES ${cu_PUBLIC_HEADERS})
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${cu_SRCS})
    set(LIBRARY_TYPE)
    set(LINK_INTERFACE_PUBLIC PUBLIC)
    set(LINK_INTERFACE_PRIVATE PRIVATE)
    if(cu_SHARED)
        message(STATUS "Building shared library!")
        set(LIBRARY_TYPE SHARED)
    endif()
    if(cu_STATIC)
        message(STATUS "Building static library!")
        set(LIBRARY_TYPE STATIC)
    endif()
    if(cu_INTERFACE)
        message(STATUS "Building Header only library!")
        set(LIBRARY_TYPE INTERFACE)
        set(LINK_INTERFACE_PUBLIC INTERFACE)
        set(LINK_INTERFACE_PRIVATE INTERFACE)    
    endif()


    add_library(${LIBRARY_NAME} ${LIBRARY_TYPE}
        ${cu_PUBLIC_HEADERS}
        ${cu_SRCS})

    message(STATUS "Adding alias library: ${cu_NAMESPACE}::${BASE_NAME}")    
    add_library(${cu_NAMESPACE}::${BASE_NAME} ALIAS ${LIBRARY_NAME})

    # Robustly handle third-party public dependencies from macro arguments
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PUBLIC_DEPS _thirdparty_public_targets)

    # Robustly handle third-party private dependencies from macro arguments
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PRIVATE_DEPS _thirdparty_private_targets)
    
    target_include_directories(${LIBRARY_NAME} ${LINK_INTERFACE_PUBLIC}
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/gen>
        $<INSTALL_INTERFACE:include/${NAMESPACE_DIR}/${BASE_NAME}>)

    target_link_libraries(${LIBRARY_NAME}
        ${LINK_INTERFACE_PUBLIC}
            ${cu_PUBLIC_DEPS}
            ${_thirdparty_public_targets}
        ${LINK_INTERFACE_PRIVATE}
            ${cu_PRIVATE_DEPS}
            ${_thirdparty_private_targets}
    )
    # on msvc add _SILENCE_STDEXT_ARR_ITERS_DEPRECATION_WARNING
    target_compile_definitions(${LIBRARY_NAME} PRIVATE
        $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:_SILENCE_STDEXT_ARR_ITERS_DEPRECATION_WARNING>
    )

    set_target_properties(${LIBRARY_NAME} PROPERTIES 
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED TRUE
        MAP_IMPORTED_CONFIG_RELWITHDEBINFO RELWITHDEBINFO RELEASE MINSIZEREL
        MAP_IMPORTED_CONFIG_MINSIZEREL MINSIZEREL RELEASE RELWITHDEBINFO
        DEBUG_POSTFIX _d
        RELWITHDEBINFO_POSTFIX _rd
        MINSIZEREL_POSTFIX _mr
        EXPORT_NAME ${BASE_NAME}
        # rpath settings
        BUILD_RPATH_USE_ORIGIN TRUE
        INSTALL_RPATH "\$ORIGIN;libs;lib;bin;modules;../libs;../lib;${cu_RPATH}"
        VERSION ${CMAKE_PROJECT_VERSION}
        )
    if (NOT MSVC)
        set_target_properties(${LIBRARY_NAME} PROPERTIES  CUDA_STANDARD 20)
    endif()

    if (cu_FOLDER)
        message(STATUS "Setting folder to ${cu_FOLDER}")
        set_target_properties(${LIBRARY_NAME} PROPERTIES FOLDER ${cu_FOLDER})
    endif()
    if (BUILD_SHARED_LIBS OR cu_SHARED)
        set_target_properties(${LIBRARY_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
        set_target_properties(${LIBRARY_NAME} PROPERTIES VISIBILITY_INLINES_HIDDEN 1)
    endif()

    if (cu_PUBLIC_DEFS)
        target_compile_definitions(${LIBRARY_NAME} ${LINK_INTERFACE_PUBLIC} ${cu_PUBLIC_DEFS})
    endif()

    if (cu_PRIVATE_DEFS)
        target_compile_definitions(${LIBRARY_NAME} ${LINK_INTERFACE_PRIVATE} ${cu_PRIVATE_DEFS})
    endif()
    if (NOT cu_INTERFACE)
        target_compile_options(${LIBRARY_NAME} PRIVATE
            $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/MP>
        )
    endif()
    if (cu_PRIVATE_COMPILE_OPTIONS)
        target_compile_options(${LIBRARY_NAME} ${LINK_INTERFACE_PRIVATE} ${cu_PRIVATE_COMPILE_OPTIONS})
    endif()

    if (cu_PUBLIC_COMPILE_OPTIONS)
        target_compile_options(${LIBRARY_NAME} ${LINK_INTERFACE_PUBLIC} ${cu_PUBLIC_COMPILE_OPTIONS})
    endif()

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/gen/${LIBRARY_NAME}-config-version.cmake"
        VERSION ${CMAKE_PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )
    include(GenerateExportHeader)    
    configure_file(cmake/config.cmake.in ${LIBRARY_NAME}-config.cmake @ONLY)
    include(GNUInstallDirs)
    install(TARGETS ${LIBRARY_NAME} EXPORT ${LIBRARY_NAME}-targets  
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${LIBRARY_NAME}_Development
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${LIBRARY_NAME}_RunTime NAMELINK_COMPONENT ${LIBRARY_NAME}_Development
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${LIBRARY_NAME}_RunTime)
    install(FILES 
            ${CMAKE_CURRENT_BINARY_DIR}/${LIBRARY_NAME}-config.cmake 
            ${CMAKE_CURRENT_BINARY_DIR}/gen/${LIBRARY_NAME}-config-version.cmake
        DESTINATION 
            share/${LIBRARY_NAME})
        
    install(EXPORT ${LIBRARY_NAME}-targets NAMESPACE ${cu_NAMESPACE}:: DESTINATION share/${LIBRARY_NAME})
    
    install(DIRECTORY
            include/
        DESTINATION include/${cu_NAMESPACE}/${BASE_NAME})
    if (NOT cu_INTERFACE)
        generate_export_header(${LIBRARY_NAME}
            EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/gen/${NAMESPACE_DIR}/${BASE_NAME}/${LIBRARY_NAME}_export.h)

        install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/gen/${NAMESPACE_DIR}/${BASE_NAME}/${LIBRARY_NAME}_export.h
            DESTINATION include/${cu_NAMESPACE}/${BASE_NAME}/${NAMESPACE_DIR}/${BASE_NAME})
    endif()
endmacro()


# Add an application (executable) with similar interface to cu_add_library
macro(cu_add_application APP_NAME)
    set(options OPTIONAL)
    set(oneValueArgs RENAME FOLDER NAMESPACE WORKING_DIRECTORY)
    set(multiValueArgs
        SRCS
        PUBLIC_DEPS
        PRIVATE_DEPS
        PUBLIC_DEFS
        PRIVATE_DEFS
        PUBLIC_COMPILE_OPTIONS
        PRIVATE_COMPILE_OPTIONS
        THIRDPARTY_PUBLIC_DEPS
        THIRDPARTY_PRIVATE_DEPS
        RPATH
    )
    cmake_parse_arguments(cu "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cu__compute_namespace_and_base(${APP_NAME} "${cu_NAMESPACE}" BASE_NAME NAMESPACE_DIR cu_NAMESPACE)

    # Source groups
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${cu_SRCS})

    set(LINK_INTERFACE_PUBLIC PUBLIC)
    set(LINK_INTERFACE_PRIVATE PRIVATE)

    add_executable(${APP_NAME} ${cu_SRCS})

    # Third-party deps
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PUBLIC_DEPS _thirdparty_public_targets)
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PRIVATE_DEPS _thirdparty_private_targets)

    target_include_directories(${APP_NAME} ${LINK_INTERFACE_PUBLIC}
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/gen>)

    target_link_libraries(${APP_NAME}
        ${LINK_INTERFACE_PUBLIC}
            ${cu_PUBLIC_DEPS}
            ${_thirdparty_public_targets}
        ${LINK_INTERFACE_PRIVATE}
            ${cu_PRIVATE_DEPS}
            ${_thirdparty_private_targets}
    )

    target_compile_definitions(${APP_NAME} PRIVATE
        $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:_SILENCE_STDEXT_ARR_ITERS_DEPRECATION_WARNING>
    )

    set_target_properties(${APP_NAME} PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED TRUE
        DEBUG_POSTFIX _d
        RELWITHDEBINFO_POSTFIX _rd
        MINSIZEREL_POSTFIX _mr
        # rpath settings
        BUILD_RPATH_USE_ORIGIN TRUE
        INSTALL_RPATH "\$ORIGIN;libs;lib;bin;modules;../libs;../lib;${cu_RPATH}"
    )
    if (NOT MSVC)
        set_target_properties(${APP_NAME} PROPERTIES CUDA_STANDARD 20)
    endif()

    if (cu_FOLDER)
        message(STATUS "Setting folder to ${cu_FOLDER}")
        set_target_properties(${APP_NAME} PROPERTIES FOLDER ${cu_FOLDER})
    endif()

    if (cu_PUBLIC_DEFS)
        target_compile_definitions(${APP_NAME} ${LINK_INTERFACE_PUBLIC} ${cu_PUBLIC_DEFS})
    endif()
    if (cu_PRIVATE_DEFS)
        target_compile_definitions(${APP_NAME} ${LINK_INTERFACE_PRIVATE} ${cu_PRIVATE_DEFS})
    endif()

    target_compile_options(${APP_NAME} PRIVATE
        $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/MP>
    )
    if (cu_PRIVATE_COMPILE_OPTIONS)
        target_compile_options(${APP_NAME} ${LINK_INTERFACE_PRIVATE} ${cu_PRIVATE_COMPILE_OPTIONS})
    endif()
    if (cu_PUBLIC_COMPILE_OPTIONS)
        target_compile_options(${APP_NAME} ${LINK_INTERFACE_PUBLIC} ${cu_PUBLIC_COMPILE_OPTIONS})
    endif()

    include(GNUInstallDirs)
    install(TARGETS ${APP_NAME}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${APP_NAME}_RunTime
        BUNDLE  DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${APP_NAME}_RunTime
    )
endmacro()


# Add a test executable and register it with CTest
macro(cu_add_test TEST_NAME)
    set(options OPTIONAL)
    set(oneValueArgs RENAME FOLDER NAMESPACE WORKING_DIRECTORY)
    set(multiValueArgs
        SRCS
        PUBLIC_DEPS
        PRIVATE_DEPS
        PUBLIC_DEFS
        PRIVATE_DEFS
        PUBLIC_COMPILE_OPTIONS
        PRIVATE_COMPILE_OPTIONS
        THIRDPARTY_PUBLIC_DEPS
        THIRDPARTY_PRIVATE_DEPS
        RPATH
        ARGS
    )
    cmake_parse_arguments(cu "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cu__compute_namespace_and_base(${TEST_NAME} "${cu_NAMESPACE}" BASE_NAME NAMESPACE_DIR cu_NAMESPACE)

    # Build the test executable (no install rule for tests by default)
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${cu_SRCS})
    add_executable(${TEST_NAME} ${cu_SRCS})

    # Third-party deps
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PUBLIC_DEPS _thirdparty_public_targets)
    cu__collect_thirdparty_targets(cu_THIRDPARTY_PRIVATE_DEPS _thirdparty_private_targets)

    target_include_directories(${TEST_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/gen>)

    target_link_libraries(${TEST_NAME}
        PUBLIC ${cu_PUBLIC_DEPS} ${_thirdparty_public_targets}
        PRIVATE ${cu_PRIVATE_DEPS} ${_thirdparty_private_targets}
    )

    if (cu_PUBLIC_DEFS)
        target_compile_definitions(${TEST_NAME} PUBLIC ${cu_PUBLIC_DEFS})
    endif()
    if (cu_PRIVATE_DEFS)
        target_compile_definitions(${TEST_NAME} PRIVATE ${cu_PRIVATE_DEFS})
    endif()

    target_compile_options(${TEST_NAME} PRIVATE
        $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/MP>
    )
    if (cu_PRIVATE_COMPILE_OPTIONS)
        target_compile_options(${TEST_NAME} PRIVATE ${cu_PRIVATE_COMPILE_OPTIONS})
    endif()
    if (cu_PUBLIC_COMPILE_OPTIONS)
        target_compile_options(${TEST_NAME} PUBLIC ${cu_PUBLIC_COMPILE_OPTIONS})
    endif()

    set_target_properties(${TEST_NAME} PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED TRUE
        DEBUG_POSTFIX _d
        RELWITHDEBINFO_POSTFIX _rd
        MINSIZEREL_POSTFIX _mr
        BUILD_RPATH_USE_ORIGIN TRUE
        INSTALL_RPATH "\$ORIGIN;libs;lib;bin;modules;../libs;../lib;${cu_RPATH}"
    )
    if (NOT MSVC)
        set_target_properties(${TEST_NAME} PROPERTIES CUDA_STANDARD 20)
    endif()
    if (cu_FOLDER)
        set_target_properties(${TEST_NAME} PROPERTIES FOLDER ${cu_FOLDER})
    endif()

    # Register with CTest using gtest_add_tests if crosscompiling, otherwise gtest_discover_tests
    if(NOT DEFINED cu_WORKING_DIRECTORY OR "${cu_WORKING_DIRECTORY}" STREQUAL "")
        set(_test_working_dir ${CMAKE_CURRENT_BINARY_DIR})
    else()
        set(_test_working_dir ${cu_WORKING_DIRECTORY})
    endif()
    message(STATUS "cu_add_test: Setting working directory for test '${TEST_NAME}' to '${_test_working_dir}'")

    include(GoogleTest)
    if(CMAKE_CROSSCOMPILING)
        gtest_add_tests(TARGET ${TEST_NAME} WORKING_DIRECTORY ${_test_working_dir} TEST_PREFIX "" TEST_LIST _added_tests)
    else()
        gtest_discover_tests(${TEST_NAME}
            WORKING_DIRECTORY ${_test_working_dir}
            PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${_test_working_dir}"
        )
    endif()
endmacro()
