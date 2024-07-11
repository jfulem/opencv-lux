# Use the official Ubuntu 22.04 base image
FROM ubuntu:22.04

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=nightly

# Update package lists
RUN apt update -y  && apt -y --no-install-recommends install tzdata

# Upgrade existing packages
RUN apt upgrade -y

RUN apt install build-essential cmake git libgtk-3-dev \
    pkg-config libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev openexr libatlas-base-dev \
    libopenexr-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev \
    python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-dev gfortran python3-pip -y
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
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='6aeece6993e902708983b209d04c0d1dbb14ebb405ddb87def578d41f920f56d' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='3c4114923305f1cd3b96ce3454e9e549ad4aa7c07c03aec73d1a785e98388bed' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='1cffbf51e63e634c746f741de50649bbbcbd9dbe1de363c9ecef64e278dba2b2' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='0a6bed6e9f21192a51f83977716466895706059afb880500ff1d0e751ada5237' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;
WORKDIR /
RUN ldconfig
# End of Dockerfile