cmake_minimum_required(VERSION 3.22...3.31)

# Name to the project
project(pFaces-AMYTISS)

# Include CMake configs for pFaces
if("$ENV{PFACES_SDK_ROOT}" STREQUAL "")
  message(FATAL_ERROR "Please make sure pFaces is installed correctly.")
else()
  include($ENV{PFACES_SDK_ROOT}/pfaces_kernel.cmake)
endif()

# Kernel name and its sources
set(PFACES_KERNEL amytiss)
set(PFACES_KERNEL_SOURCES 
    ${PROJECT_SOURCE_DIR}/kernel/amytissPDFs.cpp
    ${PROJECT_SOURCE_DIR}/kernel/amytiss.cpp
)
set(PFACES_KERNEL_OUT_PATH "${PROJECT_SOURCE_DIR}/kernel-pack")

# Add the kerel as shared lib
add_library(${PFACES_KERNEL} SHARED
    ${PFACES_KERNEL_SOURCES}
)
target_include_directories(${PFACES_KERNEL} PUBLIC
    ${PROJECT_SOURCE_DIR}/kernel
)

# Include link configs for the kernel.
include($ENV{PFACES_SDK_ROOT}/pfaces_link.cmake)
