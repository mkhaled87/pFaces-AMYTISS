cmake_minimum_required(VERSION 3.10)
project(SymbolicCpp)

# where is the src and inc dirs
set(SRC_DIR ${PROJECT_SOURCE_DIR}/src/)
set(INC_DIR ${PROJECT_SOURCE_DIR}/include/)

# add includes
include_directories(${INC_DIR})

# CMake instructions to make the static lib
ADD_LIBRARY(SymbolicCpp STATIC 
    ${SRC_DIR}/cloning.cpp
    ${SRC_DIR}/constants.cpp
    ${SRC_DIR}/equation.cpp
    ${SRC_DIR}/functions.cpp
    ${SRC_DIR}/identity.cpp
    ${SRC_DIR}/integrate.cpp
    ${SRC_DIR}/number.cpp
    ${SRC_DIR}/product.cpp
    ${SRC_DIR}/rational.cpp
    ${SRC_DIR}/solve.cpp
    ${SRC_DIR}/sum.cpp
    ${SRC_DIR}/symbol.cpp
    ${SRC_DIR}/symbolic.cpp
    ${SRC_DIR}/symbolicc++.cpp
    ${SRC_DIR}/symerror.cpp
    ${SRC_DIR}/symmatrix.cpp
    ${SRC_DIR}/vecnorm.cpp
    ${SRC_DIR}/verylong.cpp
# i removed the next as the linker says they have no symbols ! maybe !
#    ${SRC_DIR}/array.cpp
#    ${SRC_DIR}/derive.cpp
#    ${SRC_DIR}/matnorm.cpp
#    ${SRC_DIR}/matrix.cpp
#    ${SRC_DIR}/multinomial.cpp
#    ${SRC_DIR}/polynomial.cpp
#    ${SRC_DIR}/quatern.cpp
#    ${SRC_DIR}/vector.cpp    
)

# suppress some warrnings
if(UNIX OR APPLE)
target_compile_options(SymbolicCpp PRIVATE -Wno-unsequenced -Wno-dangling-else -Wno-empty-body)
endif()
if(MSVC)
target_compile_options(SymbolicCpp PRIVATE /wd4267 /wd4996 /wd4244 /wd4334 /wd4101 /wd4390)
endif()
