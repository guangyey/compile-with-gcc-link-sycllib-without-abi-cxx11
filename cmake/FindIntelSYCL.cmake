#
# Modifications, Copyright (C) 2021 Intel Corporation
#
# This software and the related documents are Intel copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may not
# use, modify, copy, publish, distribute, disclose or transmit this software or
# the related documents without Intel's prior written permission.
#
# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the
# License.
#
# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

# This will define the following variables:
# IntelSYCL_FOUND          : True if the system has the SYCL library.
# SYCL_LANGUAGE_VERSION    : The SYCL language spec version by compiler.
# SYCL_INCLUDE_DIR         : Include directories needed to use SYCL.
# SYCL_INCLUDE_SYCL_DIR    : Include directories needed to use SYCL.
# SYCL_LIBRARY_DIR         ：The path to the SYCL library.
# SYCL_LIBRARY             : SYCL library fullname.

# The following cache variables may also be set:
# SYCL_LANGUAGE_VERSION
# SYCL_INCLUDE_DIR
# SYCL_INCLUDE_SYCL_DIR
# SYCL_LIBRARY_DIR
# SYCL_LIBRARY

include(FindPackageHandleStandardArgs)

set(IntelSYCL_FOUND True)
set(INTEL_SYCL_ROOT "")
if(DEFINED ENV{INTEL_SYCL_ROOT})
  set(INTEL_SYCL_ROOT $ENV{INTEL_SYCL_ROOT})
elseif(DEFINED ENV{CMPLR_ROOT})
  set(INTEL_SYCL_ROOT $ENV{CMPLR_ROOT})
endif()

string(COMPARE EQUAL "${INTEL_SYCL_ROOT}" "" nosyclfound)
if(nosyclfound)
  set(IntelSYCL_FOUND False)
  set(SYCL_REASON_FAILURE "Intel SYCL library not set!!")
  set(IntelSYCL_NOT_FOUND_MESSAGE "${SYCL_REASON_FAILURE}")
  return()
endif()
# Can't use find_program to override the SYCL_COMPILER as Platform/ files are
# executed, potentially for a different compiler. Safer approach is to make user
# to define INTEL_SYCL_ROOT.
set(SYCL_COMPILER ${INTEL_SYCL_ROOT}/bin/icpx)

# Function to write a test case to verify SYCL features.
function(SYCL_FEATURE_TEST_WRITE src)
  set(pp_if "#if")
  set(pp_endif "#endif")

  set(SYCL_TEST_CONTENT "")
  string(APPEND SYCL_TEST_CONTENT "#include <iostream>\nusing namespace std;\n")
  string(APPEND SYCL_TEST_CONTENT "int main(){\n")

  # Feature tests goes here
  string(APPEND SYCL_TEST_CONTENT "${pp_if} defined(SYCL_LANGUAGE_VERSION)\n")
  string(APPEND SYCL_TEST_CONTENT "cout << \"SYCL_LANGUAGE_VERSION=\"<<SYCL_LANGUAGE_VERSION<<endl;\n")
  string(APPEND SYCL_TEST_CONTENT "${pp_endif}\n")

  string(APPEND SYCL_TEST_CONTENT "return 0;}\n")

  file(WRITE ${src} "${SYCL_TEST_CONTENT}")
endfunction()

# Function to build the feature check test case.
function(SYCL_FEATURE_TEST_BUILD TEST_SRC_FILE TEST_EXE)
  # Convert CXX Flag string to list
  set(SYCL_CXX_FLAGS_LIST "${SYCL_CXX_FLAGS}")
  separate_arguments(SYCL_CXX_FLAGS_LIST)

  # Spawn a process to build the test case.
  execute_process(
    COMMAND ${SYCL_COMPILER}
    ${SYCL_CXX_FLAGS_LIST}
    ${TEST_SRC_FILE}
    "-o"
    ${TEST_EXE}
    WORKING_DIRECTORY ${SYCL_TEST_DIR}
    OUTPUT_VARIABLE output ERROR_VARIABLE output
    OUTPUT_FILE ${SYCL_TEST_DIR}/Compile.log
    RESULT_VARIABLE result
    TIMEOUT 20
    )

  # Verify if test case build properly.
  if(result)
    message("SYCL feature test compile failed!")
    message("compile output is: ${output}")
  endif()
endfunction()

# Function to run the test case to generate feature info.
function(SYCL_FEATURE_TEST_RUN TEST_EXE)
  # Spawn a process to run the test case.
  execute_process(
    COMMAND ${TEST_EXE}
    WORKING_DIRECTORY ${SYCL_TEST_DIR}
    OUTPUT_VARIABLE output ERROR_VARIABLE output
    RESULT_VARIABLE result
    TIMEOUT 20
    )

  # Verify the test execution output.
  if(test_result)
    set(IntelSYCL_FOUND False)
    set(SYCL_REASON_FAILURE "SYCL feature test execution failed!!")
  endif()

  set( test_result "${result}" PARENT_SCOPE)
  set( test_output "${output}" PARENT_SCOPE)
endfunction()

# Function to extract the information from test execution.
function(SYCL_FEATURE_TEST_EXTRACT test_output)
  string(REGEX REPLACE "\n" ";" test_output_list "${test_output}")

  set(SYCL_LANGUAGE_VERSION "")
  foreach(strl ${test_output_list})
    if(${strl} MATCHES "^SYCL_LANGUAGE_VERSION=([A-Za-z0-9_]+)$")
      string(REGEX REPLACE "^SYCL_LANGUAGE_VERSION=" "" extracted_sycl_lang "${strl}")
      set(SYCL_LANGUAGE_VERSION ${extracted_sycl_lang})
    endif()
  endforeach()

  set(SYCL_LANGUAGE_VERSION "${SYCL_LANGUAGE_VERSION}" PARENT_SCOPE)
endfunction()

# use REALPATH to resolve symlinks.
get_filename_component(_REALPATH_SYCL_COMPILER "${SYCL_COMPILER}" REALPATH)
get_filename_component(SYCL_BIN_DIR "${_REALPATH_SYCL_COMPILER}" DIRECTORY)
get_filename_component(SYCL_PACKAGE_DIR "${SYCL_BIN_DIR}" DIRECTORY CACHE)

# Find include path from binary.
find_file(
  SYCL_INCLUDE_DIR
  NAMES include
  HINTS ${SYCL_PACKAGE_DIR}
  NO_DEFAULT_PATH
  )

# Find include/sycl path from include path.
find_file(
  SYCL_INCLUDE_SYCL_DIR
  NAMES sycl
  HINTS ${SYCL_PACKAGE_DIR}/include/
  NO_DEFAULT_PATH
  )

# Find library directory from binary.
find_file(
  SYCL_LIBRARY_DIR
  NAMES lib lib64
  HINTS ${SYCL_PACKAGE_DIR}
  NO_DEFAULT_PATH
  )

# Find SYCL library fullname.
find_library(
  SYCL_LIBRARY
  NAMES sycl
  HINTS ${SYCL_LIBRARY_DIR}
  NO_DEFAULT_PATH
)

if((NOT SYCL_INCLUDE_DIR) OR (NOT SYCL_INCLUDE_SYCL_DIR) OR (NOT SYCL_LIBRARY_DIR) OR (NOT SYCL_LIBRARY))
    set(IntelSYCL_FOUND False)
    set(SYCL_REASON_FAILURE "SYCL library is incomplete!!")
    set(IntelSYCL_NOT_FOUND_MESSAGE "${SYCL_REASON_FAILURE}")
    return()
endif()

set(SYCL_FLAGS "-fsycl")
# Windows: Add exception handling
if(WIN32)
  set(SYCL_FLAGS "${SYCL_FLAGS} /EHsc")
endif()

set(SYCL_CXX_FLAGS "${SYCL_FLAGS}")

# And now test the assumptions.
# Create a clean working directory.
set(SYCL_TEST_DIR "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/FindIntelSYCL")
file(REMOVE_RECURSE ${SYCL_TEST_DIR})
file(MAKE_DIRECTORY ${SYCL_TEST_DIR})

# Create the test source file.
set(TEST_SRC_FILE "${SYCL_TEST_DIR}/sycl_features.cpp")
set(TEST_EXE "${TEST_SRC_FILE}.exe")
SYCL_FEATURE_TEST_WRITE(${TEST_SRC_FILE})

# Build the test and create test executable.
SYCL_FEATURE_TEST_BUILD(${TEST_SRC_FILE} ${TEST_EXE})

# Execute the test to extract information.
SYCL_FEATURE_TEST_RUN(${TEST_EXE})

# Extract test output for information.
SYCL_FEATURE_TEST_EXTRACT(${test_output})

# As per specification, all the SYCL compatible compilers should define macro
# SYCL_LANGUAGE_VERSION.
string(COMPARE EQUAL "${SYCL_LANGUAGE_VERSION}" "" nosycllang)
if(nosycllang)
  set(IntelSYCL_FOUND False)
  set(SYCL_REASON_FAILURE "It appears that the ${SYCL_COMPILER} does not support SYCL!!")
  set(IntelSYCL_NOT_FOUND_MESSAGE "${SYCL_REASON_FAILURE}")
endif()

message(STATUS "The SYCL compiler is ${SYCL_COMPILER}")
message(STATUS "The SYCL Language Version is ${SYCL_LANGUAGE_VERSION}")

find_package_handle_standard_args(
  IntelSYCL
  FOUND_VAR IntelSYCL_FOUND
  REQUIRED_VARS SYCL_COMPILER SYCL_LANGUAGE_VERSION SYCL_INCLUDE_DIR SYCL_INCLUDE_SYCL_DIR SYCL_LIBRARY_DIR SYCL_LIBRARY
  REASON_FAILURE_MESSAGE "${SYCL_REASON_FAILURE}")

# Include in cache.
set(SYCL_LANGUAGE_VERSION "${SYCL_LANGUAGE_VERSION}" CACHE STRING "SYCL Language version")
set(SYCL_INCLUDE_DIR "${SYCL_INCLUDE_DIR}" CACHE FILEPATH "SYCL Include directory")
set(SYCL_INCLUDE_SYCL_DIR "${SYCL_INCLUDE_SYCL_DIR}" CACHE FILEPATH "SYCL Include directory")
set(SYCL_LIBRARY_DIR "${SYCL_LIBRARY_DIR}" CACHE FILEPATH "SYCL Library Directory")
set(SYCL_LIBRARY "${SYCL_LIBRARY}" CACHE STRING "SYCL Library Fullname")
