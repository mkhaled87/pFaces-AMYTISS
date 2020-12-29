#!/bin/sh

# CMake cofiguration
BUILDTYPE=Release
KERNEL_NAME=amytiss

# remove old build binaries
rm -rf kernel-pack/$KERNEL_NAME

# building ...
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=$BUILDTYPE
cmake --build . --config $BUILDTYPE
cd ..
rm -rf build
