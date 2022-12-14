#!/bin/sh

# CMake cofiguration
BUILDTYPE=Release
KERNEL_NAME=amytiss
CLEAN_BUILD=false

# remove old build binaries
if [ $CLEAN_BUILD = true ]
then 
  echo "I am doing a clean build!"
  rm -rf kernel-pack/$KERNEL_NAME.driver
  rm -rf build
fi

# building ...
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=$BUILDTYPE
cmake --build . --config $BUILDTYPE
cd ..
