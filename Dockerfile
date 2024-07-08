# Use the official Ubuntu 22.04 base image
FROM ubuntu:22.04

# Update package lists
RUN apt update -y  && apt -y --no-install-recommends install tzdata

# Upgrade existing packages
RUN apt upgrade -y

RUN apt install build-essential cmake git libgtk-3-dev \
    pkg-config libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev openexr libatlas-base-dev \
    libopenexr-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev \
    python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-dev gfortran python3-pip libopencv-dev -y
# Install Meson and Ninja
RUN python3 -m pip install meson
RUN python3 -m pip install ninja
# --> Build OpenCV
RUN mkdir /opencv_build 
WORKDIR /opencv_build
RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git
RUN mkdir -p /opencv_build/opencv/build 
WORKDIR /opencv_build/opencv/build
RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D INSTALL_C_EXAMPLES=OFF -D INSTALL_PYTHON_EXAMPLES=OFF -D OPENCV_GENERATE_PKGCONFIG=ON -D BUILD_EXAMPLES=OFF -D OPENCV_EXTRA_MODULES_PATH=/opencv_build/opencv_contrib/modules ..
RUN make -j3
RUN make install
RUN mkdir -p /opencv_build/opencv/build_static 
WORKDIR /opencv_build/opencv/build_static
RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D INSTALL_C_EXAMPLES=OFF -D INSTALL_PYTHON_EXAMPLES=OFF -D BUILD_SHARED_LIBS=OFF -D BUILD_EXAMPLES=OFF -D OPENCV_EXTRA_MODULES_PATH=/opencv_build/opencv_contrib/modules ..
RUN make -j3
RUN pkg-config --modversion opencv4
RUN ldconfig
# <-- Luxonis DepthAI
RUN mkdir /depthai
WORKDIR /depthai
RUN git clone https://github.com/luxonis/depthai-core.git
WORKDIR /depthai/depthai-core
RUN git submodule update --init --recursive
# Shared library
RUN cmake -S . -B build -D BUILD_SHARED_LIBS=ON -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D DEPTHAI_ENABLE_CURL=OFF
RUN cmake --build build --target install --parallel 2
# Static build
RUN cmake -S . -B build_static -D BUILD_SHARED_LIBS=OFF -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D DEPTHAI_ENABLE_CURL=OFF
RUN cmake --build build_static --target install --parallel 2
WORKDIR /
RUN ldconfig
# End of Dockerfile