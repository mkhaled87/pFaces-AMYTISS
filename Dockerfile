# iamge
FROM ubuntu:18.04

# update image
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils
RUN apt-get -y upgrade

# install required libs/tools
RUN apt-get install -y wget git unzip build-essential libcpprest-dev opencl-c-headers  opencl-clhpp-headers ocl-icd-opencl-dev
RUN apt-get install -y clinfo oclgrind

# install pfaces and AMYTISS
RUN mkdir pfaces; cd pfaces; wget https://github.com/parallall/pFaces/releases/download/Release_1.1.0d/pFaces-1.1.0-Ubuntu18.04.zip; unzip pFaces-1.1.0-Ubuntu18.04.zip; sh ./install.sh
RUN git clone --depth=1 https://github.com/mkhaled87/pFaces-AMYTISS
RUN cd pFaces-AMYTISS; export PFACES_SDK_ROOT=$PWD/../pfaces/pfaces-sdk/; make
