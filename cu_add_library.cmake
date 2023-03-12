function(cu_add_library LIBRARY_NAME)
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
    )
    cmake_parse_arguments(PARSE_ARGV 1
        "cu" #prefix
        "${options}" #options
        "${oneValueArgs}" # one value arguments
        "${multiValueArgs}") # multi value arguments
    

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
    
    target_include_directories(${LIBRARY_NAME} ${LINK_INTERFACE_PUBLIC}
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/gen>
        $<INSTALL_INTERFACE:include/${NAMESPACE_DIR}/${BASE_NAME}>)

    target_link_libraries(${LIBRARY_NAME}
        ${LINK_INTERFACE_PUBLIC}
            ${cu_PUBLIC_DEPS}
        ${LINK_INTERFACE_PRIVATE}
            ${cu_PRIVATE_DEPS}
    )
    
    set_target_properties(${LIBRARY_NAME} PROPERTIES 
        CXX_STANDARD 17
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
        set_target_properties(${LIBRARY_NAME} PROPERTIES  CUDA_STANDARD 14)
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
endfunction()
