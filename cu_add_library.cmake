function(cu_add_library LIBRARY_NAME)
    set(options OPTIONAL)
    set(oneValueArgs RENAME FOLDER NAMESPACE)
    set(multiValueArgs PUBLIC_HEADERS SRCS PUBLIC_DEPS PRIVATE_DEPS PUBLIC_DEFS PRIVATE_DEFS PUBLIC_COMPILE_OPTIONS PRIVATE_COMPILE_OPTIONS)
    cmake_parse_arguments(PARSE_ARGV 1
        "cu" #prefix
        "${options}" #options
        "${oneValueArgs}" # one value arguments
        "${multiValueArgs}") # multi value arguments
    
    add_library(${LIBRARY_NAME}
        ${cu_PUBLIC_HEADERS}
        ${cu_SRCS})
    
    string(REGEX REPLACE "^${cu_NAMESPACE}_" #matches at beginning of input
       "" BASE_NAME ${LIBRARY_NAME})
    
    message(STATUS "Adding alias library: ${cu_NAMESPACE}::${BASE_NAME}")    
    
    add_library(${cu_NAMESPACE}::${BASE_NAME} ALIAS ${LIBRARY_NAME})
    
    target_include_directories(${LIBRARY_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:include/${cu_NAMESPACE}/${BASE_NAME}>)
    
    target_link_libraries(${LIBRARY_NAME} PUBLIC ${cu_PUBLIC_DEPS}
        PRIVATE ${cu_PRIVATE_DEPS})
    set_target_properties(${LIBRARY_NAME} PROPERTIES 
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED TRUE
        MAP_IMPORTED_CONFIG_RELWITHDEBINFO RELWITHDEBINFO RELEASE MINSIZEREL
        MAP_IMPORTED_CONFIG_MINSIZEREL MINSIZEREL RELEASE RELWITHDEBINFO
        DEBUG_POSTFIX _d
        RELWITHDEBINFO_POSTFIX _rd
        MINSIZEREL_POSTFIX _mr
        EXPORT_NAME ${BASE_NAME})

    if (cu_FOLDER)
        set_target_properties(${LIBRARY_NAME} PROPERTIES FOLDER ${cu_FOLDER})
    endif()
    if (BUILD_SHARED_LIBS)
        set_target_properties(${LIBRARY_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
        set_target_properties(${LIBRARY_NAME} PROPERTIES VISIBILITY_INLINES_HIDDEN 1)
    endif()

    if (cu_PUBLIC_DEFS)
        target_compile_definitions(${LIBRARY_NAME} PUBLIC ${cu_PUBLIC_DEFS})
    endif()

    if (cu_PRIVATE_DEFS)
        target_compile_definitions(${LIBRARY_NAME} PRIVATE ${cu_PRIVATE_DEFS})
    endif()
    
    if (cu_PRIVATE_COMPILE_OPTIONS)
        target_compile_options(${LIBRARY_NAME} PRIVATE ${cu_PRIVATE_COMPILE_OPTIONS})
    endif()

    if (cu_PUBLIC_COMPILE_OPTIONS)
        target_compile_options(${LIBRARY_NAME} PUBLIC ${cu_PUBLIC_COMPILE_OPTIONS})
    endif()

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/gen/${PROJECT_NAME}-config-version.cmake"
        VERSION ${CMAKE_PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )
    include(GenerateExportHeader)
    generate_export_header(${LIBRARY_NAME}
        EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/gen/${cu_NAMESPACE}/${BASE_NAME}/${LIBRARY_NAME}_export.h)
    
    
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
            lib/cmake/${LIBRARY_NAME})
        
    install(EXPORT ${LIBRARY_NAME}-targets NAMESPACE ${cu_NAMESPACE}:: DESTINATION lib/cmake/${LIBRARY_NAME})
    
    install(DIRECTORY
            include/
        DESTINATION include/${cu_NAMESPACE}/${BASE_NAME})
    install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/gen/${cu_NAMESPACE}/${BASE_NAME}/${LIBRARY_NAME}_export.h
        DESTINATION include/${cu_NAMESPACE}/${BASE_NAME}/${cu_NAMESPACE}/${BASE_NAME})
endfunction()