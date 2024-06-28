# Use the official Ubuntu 22.04 base image
FROM ubuntu:22.04

# Update package lists
RUN apt update -y

# Upgrade existing packages
RUN apt upgrade -y

RUN apt install meson ninja-build -y
RUN apt install build-essential cmake git libgtk-3-dev \
    pkg-config libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev openexr libatlas-base-dev \
    libopenexr-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev \
    python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-dev gfortran -y

RUN mkdir /opencv_build && cd /opencv_build
RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git
RUN mkdir -p /opencv_build/opencv/build && cd /opencv_build/opencv/build
RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D INSTALL_C_EXAMPLES=OFF -D INSTALL_PYTHON_EXAMPLES=OFF -D OPENCV_GENERATE_PKGCONFIG=ON -D BUILD_EXAMPLES=OFF -D OPENCV_EXTRA_MODULES_PATH=/opencv_build/opencv_contrib/modules ..
RUN make -j3
RUN make install
RUN pkg-config --modversion opencv4

# Install any additional packages you need (e.g., curl, nginx, etc.)
# Example:
# RUN apt-get install -y curl

# Set up your application-specific configurations
# Example:
# COPY my_app_config.conf /etc/my_app/

# Define the default command to run when the container starts
# Example:
# CMD ["nginx", "-g", "daemon off;"]

# Expose any necessary ports
# Example:
# EXPOSE 80

# Add other instructions as needed for your specific use case

# End of Dockerfile