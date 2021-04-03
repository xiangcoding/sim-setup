#!/bin/bash

# the script to compile and set up simulation environment.
# takes long time, need to re-type sudo password during the execution after timeout

#TODO: checkout correct verion of fog_sw
#TODO: add debug flag -d 
#DONE: add PATH to .bashrc

: <<'END'
END


# setup locale
sudo apt update 
sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8


# compatibility layer between Python 2 and Python 3 (future)
pip3 install --user future # required by mavlink router


# add repo of ROS2
sudo apt install   gnupg2 lsb-release -y
sudo apt install -y curl
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

sudo apt update

# install dependency

sudo apt install -y \
    build-essential \
    dh-make debhelper \
    fakeroot \
    git \
    golang \
    libasio-dev \
    openjdk-11-jdk-headless \
    openssh-client \
    python3-bloom \
    python3-pip \
    python3-future \
    python3-genmsg \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    nlohmann-json3-dev \
    zlib1g-dev \
    libusb-1.0-0-dev \
    freeglut3-dev \
    liblapacke-dev \
    libopenblas-dev \
    libatlas-base-dev



pip3 install --user pyros-genmsg
# install requirements needed by px4
pip3 install --user jinja2  toml

# install ROS2
sudo apt install -y \
	ros-foxy-ros-base \
	ros-foxy-geodesy 
	

# python-colcon also needs ros repo
# colcon-common always triger errors
# double check do we still need this in new packing method
# should be installed after ros installation
sudo apt install -y python3-colcon-common-extensions


# depthai needs gstreamer1.0-plugins-bad, gstreamer1.0-libav and gir1.2-gst-rtsp-server-1.0
sudo apt install -y \
	gstreamer1.0-plugins-bad \
	gstreamer1.0-libav \
	gir1.2-gst-rtsp-server-1.0



# communication link requires gstreamer1.0-rtsp
sudo apt install gstreamer1.0-rtsp



# download source code from github repo
pushd .
git clone  https://github.com/tiiuae/fog_sw.git --recursive
cd fog_sw
git submodule update --init --recursive
popd 

# fastrtpslib is still needed by px4, but not in fog_sw repo
# so, fetch from own repo
pushd .

curl -LO https://github.com/xiangcoding/sim-setup/raw/main/tools/fastrtpslib_1.0.0~v1.8.2_amd64.deb
# pay attention to update version
sudo dpkg -i fastrtpslib_1.0.0~v1.8.2_amd64.deb
#rm fastrtpslib_1.0.0~v1.8.2_amd64.deb

popd 

# mavlink ctrl required by colcon build for fog_sw component
pushd .
cd fog_sw/tools
sudo dpkg -i mavsdk_*.deb

# fastrtpsgen required by px4_sitl_rtps
# name changed to fastddsgen
sudo dpkg -i fastddsgen*.deb

sudo dpkg -i libsurvive*.deb

popd



# download px4-firmware
pushd .
git clone https://github.com/tiiuae/px4-firmware.git --recursive
cd px4-firmware
git submodule update --init --recursive
popd



# install Gazebo related packages
sudo apt-get install gazebo9 libgazebo9-dev libgstreamer-plugins-base1.0-dev \
	libopencv-dev -y



source /opt/ros/foxy/setup.bash


# update ROSDEP
pushd .
cd fog_sw

sudo sh -c 'mkdir -p /etc/ros/rosdep/sources.list.d'
sudo sh -c 'echo "yaml file://${PWD}/rosdep.yaml" > /etc/ros/rosdep/sources.list.d/50-fogsw.list'
if [ ! -e /etc/ros/rosdep/sources.list.d/20-default.list ]; then
	echo "--- Initialize rosdep"
	sudo rosdep init
fi
echo "--- Updating rosdep"
rosdep update

popd


# building fog_sw packages 

pushd .
cd fog_sw/packaging
./package.sh

popd 


: <<'END'
# build only mavlink-router

pushd .
cd fog_sw/packaging
pushd mavlink-router
./package.sh
popd
popd
END


# add PATH to .bashrc
pushd .
cd fog_sw/mavlink-router
CURR_DIR=`pwd`

#TODO: how to prevent multiple same entries with multiple run
echo "export PATH=$CURR_DIR:\$PATH/">>/home/$USER/.bashrc
echo "source /opt/ros/foxy/setup.bash">>/home/$USER/.bashrc
popd

pushd .
CURR_DIR=`pwd`
echo "export PATH=$CURR_DIR/fog_sw/ros2_ws/src/px4_mavlink_ctrl/launch/:\$PATH/">>/home/$USER/.bashrc
popd 

source ~/.bashrc

pushd .
cd fog_sw/packaging

# install the generated packages

# do we need to care about sequence while dpkg -i *.deb? 


sudo dpkg -i agent-protocol-splitter*.deb


sudo dpkg -i communication-link*.deb
sudo dpkg -i fog-sw-ros-systemd-services*.deb

sudo dpkg -i mavlink-router*.deb

# depthai needs gstreamer1.0-plugins-bad, gstreamer1.0-libav and gir1.2-gst-rtsp-server-1.0
	
sudo dpkg -i ros-foxy-depthai-ctrl*.deb

sudo dpkg -i ros-foxy-px4-mavlink-ctrl*.deb

sudo dpkg -i ros-foxy-px4-msgs*.deb

sudo dpkg -i ros-foxy-indoor-pos_1.0.0-0focal_amd64.deb
sudo dpkg -i ros-foxy-px4-ros-com_0.1.0-0focal_amd64.deb

popd

pushd .
cd px4-firmware
# test if DONT_RUN works 
DONT_RUN=1 make px4_sitl_rtps gazebo_ssrc_fog_x


