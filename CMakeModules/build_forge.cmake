INCLUDE(ExternalProject)

SET(prefix ${PROJECT_BINARY_DIR}/third_party/forge)

# FIXME: Cannot use $<CONFIG> generator expression here because add_custom_command
#        does not yet support it for the OUTPUT argument, see also:
#        - Old "duplicate":   https://cmake.org/Bug/view.php?id=12877
#        - Old issue tracker: https://cmake.org/Bug/view.php?id=13840
#        - New issue tracker: https://gitlab.kitware.com/cmake/cmake/issues/13840
#        In the meantime, use CMAKE_BUILD_TYPE if set by user, assuming that it
#        is the primary build configuration used. Otherwise, default to Release.
IF(CMAKE_BUILD_TYPE)
    SET(forge_lib_config ${CMAKE_BUILD_TYPE})
ELSE()
    SET(forge_lib_config Release)
ENDIF()
IF(CMAKE_GENERATOR MATCHES "Xcode") # TODO: Also for "Visual Studio"?
    SET(forge_lib_infix "/${forge_lib_config}")
ELSE()
    SET(forge_lib_infix)
ENDIF()
IF(WIN32)
    SET(forge_lib_prefix "${prefix}/lib")
ELSE(WIN32)
    SET(forge_lib_prefix "${prefix}/src/forge-ext-build/src")
ENDIF(WIN32)

SET(forge_location "${forge_lib_prefix}${forge_lib_infix}/${CMAKE_SHARED_LIBRARY_PREFIX}forge${CMAKE_SHARED_LIBRARY_SUFFIX}")
IF(CMAKE_VERSION VERSION_LESS 3.2)
    IF(CMAKE_GENERATOR MATCHES "Ninja")
        MESSAGE(WARNING "Building forge with Ninja has known issues with CMake older than 3.2")
    endif()
    SET(byproducts)
ELSE()
    SET(byproducts BYPRODUCTS ${forge_location})
ENDIF()

# FIXME Tag forge correctly during release
ExternalProject_Add(
    forge-ext
    GIT_REPOSITORY https://github.com/arrayfire/forge.git
    GIT_TAG master
    PREFIX "${prefix}"
    INSTALL_DIR "${prefix}"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -Wno-dev "-G${CMAKE_GENERATOR}" <SOURCE_DIR>
    -DCMAKE_SOURCE_DIR:PATH=<SOURCE_DIR>
    -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
    -DUSE_GLEWmx_STATIC:BOOL=${USE_GLEWmx_STATIC}
    -DGLEW_ROOT_DIR:STRING=${GLEW_ROOT_DIR}
    -DGLFW_ROOT_DIR:STRING=${GLFW_ROOT_DIR}
    -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
    -DBUILD_EXAMPLES:BOOL=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${forge_lib_config}
    ${byproducts}
    )

ExternalProject_Get_Property(forge-ext binary_dir)
ExternalProject_Get_Property(forge-ext install_dir)
ADD_LIBRARY(forge SHARED IMPORTED)
SET_TARGET_PROPERTIES(forge PROPERTIES IMPORTED_LOCATION ${forge_location})
IF(WIN32)
    SET_TARGET_PROPERTIES(forge PROPERTIES IMPORTED_IMPLIB ${forge_lib_prefix}/forge.lib)
ELSE(WIN32)
    SET(forge_bindir_location ${binary_dir}/src${forge_lib_infix}/${CMAKE_SHARED_LIBRARY_PREFIX}forge${CMAKE_SHARED_LIBRARY_SUFFIX})
    IF(NOT (${forge_bindir_location} STREQUAL ${forge_location}))
        MESSAGE(WARNING "Did the forge binary location move? (Have ${forge_bindir_location} vs ${forge_location})")
    ENDIF()
ENDIF(WIN32)
ADD_DEPENDENCIES(forge forge-ext)
SET(FORGE_INCLUDE_DIRECTORIES ${install_dir}/include)
SET(FORGE_LIBRARIES forge)
SET(FORGE_FOUND ON)
