cmake_minimum_required(VERSION 3.6)

# Name to the project
project(pFaces-AMYTISS)

# Include CMake configs for pFaces
if("$ENV{PFACES_SDK_ROOT}" STREQUAL "")
  message(FATAL_ERROR "Please make sure pFaces is installed correctly.")
else()
  include($ENV{PFACES_SDK_ROOT}/pfaces_kernel.cmake)
endif()


# Libraries needed fot this kernel: SymbolicCPP
add_subdirectory(${PROJECT_SOURCE_DIR}/kernel/symboliccpp)

# Kernel name and its sources
set(PFACES_KERNEL amytiss)
set(PFACES_KERNEL_SOURCES 
    ${PROJECT_SOURCE_DIR}/kernel/amytissPDFs.cpp
    ${PROJECT_SOURCE_DIR}/kernel/amytiss.cpp
)
set(PFACES_KERNEL_OUT_PATH "${PROJECT_SOURCE_DIR}/kernel-pack")

# Generic CMake instructions to make the kernel
link_directories($ENV{PFACES_SDK_ROOT}/lib)
ADD_LIBRARY(${PFACES_KERNEL} SHARED
    ${PFACES_KERNEL_SOURCES}
)
target_include_directories(${PFACES_KERNEL} PUBLIC
    ${OpenCL_INCLUDE_DIR}
    $ENV{PFACES_SDK_ROOT}/include
    ${PROJECT_SOURCE_DIR}/kernel/symboliccpp/include
)
set_target_properties(${PFACES_KERNEL}
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${PFACES_KERNEL_OUT_PATH}"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${PFACES_KERNEL_OUT_PATH}"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${PFACES_KERNEL_OUT_PATH}"
    ARCHIVE_OUTPUT_DIRECTORY "${PFACES_KERNEL_OUT_PATH}"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${PFACES_KERNEL_OUT_PATH}"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${PFACES_KERNEL_OUT_PATH}"
    RUNTIME_OUTPUT_DIRECTORY "${PFACES_KERNEL_OUT_PATH}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PFACES_KERNEL_OUT_PATH}"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PFACES_KERNEL_OUT_PATH}"
    SUFFIX ".driver"
    PREFIX ""
)
if (MSVC)
    set_target_properties(${PFACES_KERNEL} PROPERTIES LINK_FLAGS "/WHOLEARCHIVE:pfaces-sdk.lib")
    target_link_libraries(${PFACES_KERNEL} ${OpenCL_LIBRARY} SymbolicCpp)
elseif (APPLE)
    set_target_properties(${PFACES_KERNEL} PROPERTIES LINK_FLAGS "-Wl,-all_load -lpfaces-sdk")
    target_link_libraries(${PFACES_KERNEL} ${OpenCL_LIBRARY} SymbolicCpp dl pthread)
else()
    set_target_properties(${PFACES_KERNEL} PROPERTIES LINK_FLAGS "-Wl,--whole-archive -lpfaces-sdk -Wl,--no-whole-archive")
    target_link_libraries(${PFACES_KERNEL} ${OpenCL_LIBRARY} SymbolicCpp)
endif()

# suppress some warnings
if(UNIX OR APPLE)
    target_compile_options(${PFACES_KERNEL} PRIVATE -Wno-deprecated -Wno-ignored-attributes -Wno-nullability-completeness-on-arrays)
elseif(MSVC)
    target_compile_options(${PFACES_KERNEL} PRIVATE /wd4267 /wd4996 /wd4101 /wd4390 /wd4244)
endif()


