# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

# Set CMake policy
cmake_policy(SET CMP0010 NEW)

# Define BLIS source path
# AOCL 5.2.1+ uses submodules for reproducible builds
set(BLIS_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/submodules/blis")

# Verify BLIS submodule exists
if(NOT EXISTS "${BLIS_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR 
        "BLIS submodule not found at ${BLIS_SOURCE_DIR}. "
        "Ensure git submodules are initialized: git submodule update --init")
endif()

message(STATUS "Using BLIS source code from ${BLIS_SOURCE_DIR}")

# Configure BLIS build options
# These variables are consumed by BLIS's CMakeLists.txt
set(BLIS_CONFIG_FAMILY "${BLIS_CONFIG_FAMILY}" CACHE STRING "BLIS architecture family")
set(ENABLE_CBLAS "${ENABLE_CBLAS}" CACHE BOOL "Enable CBLAS interface")
set(ENABLE_ADDON "${ENABLE_ADDON}" CACHE BOOL "Enable BLIS addons")
set(ENABLE_THREADING "${ENABLE_THREADING}" CACHE STRING "BLIS threading mode")
set(BLAS_INT_SIZE "${BLAS_INT_SIZE}" CACHE STRING "BLAS integer size (32 or 64)")
set(COMPLEX_RETURN "${COMPLEX_RETURN}" CACHE STRING "Complex return convention")
set(ENABLE_TRSM_PREINVERSION "${ENABLE_TRSM_PREINVERSION}" CACHE BOOL "Enable TRSM preinversion")

# OpenMP configuration (if enabled)
if(OpenMP_libomp_LIBRARY)
    set(OpenMP_libomp_LIBRARY "${OpenMP_libomp_LIBRARY}" CACHE STRING "OpenMP library")
endif()

# Configure BLIS installation directory
# BLIS will install to CMAKE_INSTALL_PREFIX/blis/* by default
# We override to install directly to CMAKE_BINARY_DIR/blis/install_package
set(BLIS_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/blis/install_package" CACHE PATH "BLIS install directory")

# Add BLIS as a subdirectory
# This properly integrates BLIS into the AOCL build:
# - BLIS builds at build time (not configure time)
# - Parallel builds work correctly
# - Environment (PATH, INCLUDE, LIB) propagates naturally
# - Dependency tracking works (incremental builds)
# - Targets are available for use in AOCL
add_subdirectory("${BLIS_SOURCE_DIR}" "${CMAKE_BINARY_DIR}/blis/build_dir" EXCLUDE_FROM_ALL)

# Note: BLIS will use its own CMAKE_INSTALL_PREFIX settings from add_subdirectory()
# We don't need to override the target properties here.

message(STATUS "BLIS configured successfully via add_subdirectory()")
message(STATUS "BLIS will install to: ${BLIS_INSTALL_PREFIX}")

# Export BLIS targets for use by AOCL
# The 'blis' target is now available for linking and will be built when needed

# For compatibility with AOCL's unified library approach:
# AOCL creates a monolithic library combining multiple components.
#
# The original approach (collecting object files with file(GLOB) at configure time)
# was fundamentally broken - object files don't exist until BUILD time!
#
# Proper solution: Have AOCL link against the 'blis' target using WHOLE_ARCHIVE
# or convert BLIS to an OBJECT library. For now, we let BLIS build and install
# normally, and AOCL's main CMakeLists.txt will need to be updated to link properly.
#
# TODO: Update AOCL's main CMakeLists.txt to:
#   target_link_libraries(aocl PRIVATE $<TARGET_FILE:blis>)
# or
#   target_link_libraries(aocl PRIVATE -Wl,--whole-archive blis -Wl,--no-whole-archive)

# For backward compatibility, we export the blis target to parent scope
# so it can be referenced by the main CMakeLists.txt
set(BLIS_TARGET "blis" PARENT_SCOPE)
set(BLIS_BINARY_DIR "${CMAKE_BINARY_DIR}/blis/build_dir" PARENT_SCOPE)

message(STATUS "BLIS target 'blis' is now available for linking")
message(STATUS "Recommend updating AOCL to link against blis target instead of collecting object files")
