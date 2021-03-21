#!/bin/bash

# this script will install packages required by source code compiling

# set up essential develop environment
sudo apt install build-essential  git curl -y
sudo apt-get install python3-pip -y

# install Java
sudo apt install  openjdk-11-jre  -y

# install Go
sudo apt install  golang-go -y

sudo apt install  python3-rosdep -y

sudo apt install   gnupg2 lsb-release -y




pip3 install --user pyros-genmsg
pip3 install --user future # required by mavlink router

# add repo of ROS2
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
# should we use a static url?
# sudo sh -c 'echo "deb [arch=amd64] http://packages.ros.org/ros2/ubuntu focal main" > /etc/apt/sources.list.d/ros2-latest.list'


sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'


sudo apt-get update
# in case upgrade fails, auto fix it
sudo apt upgrade -y
sudo apt --fix-broken install -y

# install ROS2
sudo apt install ros-foxy-desktop -y

# install Gazebo related
sudo apt-get install gazebo9 libgazebo9-dev libgstreamer-plugins-base1.0-dev \
  libopencv-dev -y


# required by sitl_gazebo
sudo apt install python3-toml  python3-jinja2 -y

# source code compiling, building needed
sudo apt-get install python3-bloom dh-make debhelper fakeroot -y
sudo apt install python3-colcon-common-extensions -y

# download source code from github repo
# download source code from github
pushd .
git clone  https://github.com/tiiuae/fog_sw.git --recursive
cd fog_sw
git submodule update --init --recursive
popd 

# mavlink ctrl required by colcon build for fog_sw component
pushd .
cd fog_sw/tools
sudo dpkg -i mavsdk_0.34.0_ubuntu20.04_amd64.deb

# fastrtpsgen required by px4_sitl_rtps
sudo dpkg -i fastrtps*.deb
popd

# is ./fog_sw/build_setup.sh needed?

# colcon build
pushd .
source /opt/ros/foxy/setup.bash
cd fog_sw/ros2_ws
colcon build
popd

# generate executable files such as mavlink_routerd, 
pushd .
cd fog_sw/packaging
./package.sh
popd


# mavlink router config file
pushd .
sudo mkdir  /etc/mavlink-router
sudo cp fog_sw/packaging/mavlink-router/main.conf  /etc/mavlink-router
popd 


# setup device id
sudo mkdir /enclave
sudo touch /enclave/drone_device_id
sudo chmod o+w /enclave/drone_device_id
sudo echo  DRONE_DEVICE_ID=device_id_123abc >/enclave/drone_device_id

# setup RSA key pair for ROS node
openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
sudo cp rsa_private.pem /enclave/
sudo chmod o+r /enclave/rsa_private.pem


pushd .
git clone https://github.com/tiiuae/px4-firmware.git --recursive
cd px4-firmware
git submodule update --init --recursive
git tag -d px4_sitl_pre181220 
popd

