macro(generat_gitversion)
    find_program (GITVERSION_EXE NAMES dotnet-gitversion gitversion)

    if (NOT GITVERSION_EXE)
        set(CMAKE_PROJECT_VERSION 0.0.0)
        message(WARNING "Cannot find gitversion, using version ${CMAKE_PROJECT_VERSION}!")
    else()
        message(STATUS "Find gitversion: ${GITVERSION_EXE}")

        message(STATUS "Starting gitversion execution.")
        execute_process(COMMAND ${GITVERSION_EXE}
                        OUTPUT_VARIABLE gitversion_gen_output
                        RESULT_VARIABLE gitversion_gen_result
                        ERROR_VARIABLE gitversion_gen_error
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    )
        message(STATUS "gitversion errors: \n${gitversion_gen_error}")
        message(STATUS "**************************************************************************")

        if(NOT gitversion_gen_result EQUAL 0)
            message(FATAL_ERROR "gitversion failed with status: ${gitversion_gen_result}")
        endif()

        #string(JSON MINOR_VERSION GET ${gitversion_gen_output} 0)
        string(JSON MAJOR_VERSION GET ${gitversion_gen_output} "Major")
        string(JSON MINOR_VERSION GET ${gitversion_gen_output} "Minor")
        string(JSON PATCH_VERSION GET ${gitversion_gen_output} "Patch")
        string(JSON PreReleaseTag GET ${gitversion_gen_output} "PreReleaseTag")
        string(JSON FullBuildMetaData GET ${gitversion_gen_output} "FullBuildMetaData")
        string(JSON SemVer GET ${gitversion_gen_output} "SemVer")
        string(JSON FullSemVer GET ${gitversion_gen_output} "FullSemVer")
        string(JSON BranchName GET ${gitversion_gen_output} "BranchName")
        string(JSON Sha GET ${gitversion_gen_output} "Sha")
        string(JSON UncommittedChanges GET ${gitversion_gen_output} "UncommittedChanges")
        string(JSON CommitDate GET ${gitversion_gen_output} "CommitDate")

        set(CMAKE_PROJECT_VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION})
    endif()

endmacro(generat_gitversion)
