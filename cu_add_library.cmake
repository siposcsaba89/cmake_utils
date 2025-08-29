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
    

    string(REGEX REPLACE "^${cu_NAMESPACE}_" #matches at beginning of input
        "" BASE_NAME ${LIBRARY_NAME})
    set(NAMESPACE_DIR ${cu_NAMESPACE})
    if (NOT cu_NAMESPACE)
        set(NAMESPACE_DIR ".")
        set(cu_NAMESPACE ${LIBRARY_NAME})
    elseif(${cu_NAMESPACE} STREQUAL ${LIBRARY_NAME})
        set(NAMESPACE_DIR ".")
    endif()
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
    set(_thirdparty_public_targets)
    set(_current_package "")
    set(_current_targets "")
    foreach(_arg IN LISTS cu_THIRDPARTY_PUBLIC_DEPS)
        string(FIND "${_arg}" ":" _colon_idx)
        if(_colon_idx GREATER -1)
            # New package:target(s) entry
            if(NOT _current_package STREQUAL "")
                # Process previous package and its targets
                message(STATUS "Finding package: ${_current_package} for all listed targets")
                find_package(${_current_package} REQUIRED)
                string(REPLACE ";" ";" _targets "${_current_targets}")
                foreach(_target IN LISTS _targets)
                    message(STATUS "Processing third-party dependency: package='${_current_package}', target='${_target}'")
                    if(TARGET ${_target})
                        list(APPEND _thirdparty_public_targets ${_target})
                    else()
                        message(WARNING "Target ${_target} from package ${_current_package} not found!")
                    endif()
                endforeach()
            endif()
            string(SUBSTRING "${_arg}" 0 ${_colon_idx} _current_package)
            math(EXPR _targets_start "${_colon_idx} + 1")
            string(SUBSTRING "${_arg}" ${_targets_start} -1 _current_targets)
        else()
            # Additional target for previous package
            if(NOT _current_package STREQUAL "")
                set(_current_targets "${_current_targets};${_arg}")
            endif()
        endif()
    endforeach()
    if(NOT _current_package STREQUAL "")
        message(STATUS "Finding package: ${_current_package} for all listed targets")
        find_package(${_current_package} REQUIRED)
        string(REPLACE ";" ";" _targets "${_current_targets}")
        foreach(_target IN LISTS _targets)
            message(STATUS "Processing third-party dependency: package='${_current_package}', target='${_target}'")
            if(TARGET ${_target})
                list(APPEND _thirdparty_public_targets ${_target})
            else()
                message(WARNING "Target ${_target} from package ${_current_package} not found!")
            endif()
        endforeach()
    endif()

    # Robustly handle third-party private dependencies from macro arguments
    set(_thirdparty_private_targets)
    set(_current_package "")
    set(_current_targets "")
    foreach(_arg IN LISTS cu_THIRDPARTY_PRIVATE_DEPS)
        string(FIND "${_arg}" ":" _colon_idx)
        if(_colon_idx GREATER -1)
            if(NOT _current_package STREQUAL "")
                message(STATUS "Finding package: ${_current_package} for all listed targets")
                find_package(${_current_package} REQUIRED)
                string(REPLACE ";" ";" _targets "${_current_targets}")
                foreach(_target IN LISTS _targets)
                    message(STATUS "Processing third-party dependency: package='${_current_package}', target='${_target}'")
                    if(TARGET ${_target})
                        list(APPEND _thirdparty_private_targets ${_target})
                    else()
                        message(WARNING "Target ${_target} from package ${_current_package} not found!")
                    endif()
                endforeach()
            endif()
            string(SUBSTRING "${_arg}" 0 ${_colon_idx} _current_package)
            math(EXPR _targets_start "${_colon_idx} + 1")
            string(SUBSTRING "${_arg}" ${_targets_start} -1 _current_targets)
        else()
            if(NOT _current_package STREQUAL "")
                set(_current_targets "${_current_targets};${_arg}")
            endif()
        endif()
    endforeach()
    if(NOT _current_package STREQUAL "")
        message(STATUS "Finding package: ${_current_package} for all listed targets")
        find_package(${_current_package} REQUIRED)
        string(REPLACE ";" ";" _targets "${_current_targets}")
        foreach(_target IN LISTS _targets)
            message(STATUS "Processing third-party dependency: package='${_current_package}', target='${_target}'")
            if(TARGET ${_target})
                list(APPEND _thirdparty_private_targets ${_target})
            else()
                message(WARNING "Target ${_target} from package ${_current_package} not found!")
            endif()
        endforeach()
    endif()
    
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
