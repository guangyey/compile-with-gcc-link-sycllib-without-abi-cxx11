cmake_minimum_required(VERSION 3.13 FATAL_ERROR)
project(demo VERSION 0.0)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(IntelSYCL QUIET)

if(NOT IntelSYCL_FOUND)
  message(STATUS "Could NOT find SYCL.(${IntelSYCL_NOT_FOUND_MESSAGE})")
  return()
endif()

add_library(sycl INTERFACE IMPORTED)

set_property(
  TARGET sycl PROPERTY INTERFACE_INCLUDE_DIRECTORIES
  ${SYCL_INCLUDE_DIR}
  ${SYCL_INCLUDE_SYCL_DIR})
set_property(
  TARGET sycl PROPERTY INTERFACE_LINK_LIBRARIES
  ${SYCL_LIBRARY})

message(STATUS "  Intel SYCL include  : ${SYCL_INCLUDE_DIR}")
message(STATUS "  Intel SYCL library  : ${SYCL_LIBRARY}")

string(APPEND CMAKE_CXX_FLAGS " -Wall")
string(APPEND CMAKE_CXX_FLAGS " -Wextra")
string(APPEND CMAKE_CXX_FLAGS " -D_GLIBCXX_USE_CXX11_ABI=0")

file(GLOB SOURCES ${CMAKE_CURRENT_LIST_DIR}/*.cpp ${CMAKE_CURRENT_LIST_DIR}/*.h)

add_executable(demo ${SOURCES})
set_target_properties(demo PROPERTIES CXX_STANDARD 17)
set_target_properties(demo PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(demo PUBLIC sycl)

message(STATUS "  CMAKE_CXX_FLAGS  : ${CMAKE_CXX_FLAGS}")
message(STATUS "  SOURCES          : ${SOURCES}")
