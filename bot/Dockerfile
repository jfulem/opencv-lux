# Use the official Ubuntu 22.04 base image
FROM jfulem/opencv-lux:4.10.rust
RUN apt install software-properties-common -y
RUN apt update -y
RUN add-apt-repository ppa:xmake-io/xmake -y
RUN apt install xmake zip unzip p7zip-full -y
RUN adduser --system --group --disabled-password --gecos '' bot
USER bot:bot
# End of Dockerfiles