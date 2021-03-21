#!/bin/bash
# sequential steps of Ben's script

git clone https://github.com/rudislabs/tii_ws.git

# configuration
cd tii_ws
mkdir src
cp config/tii_mocap_sim.rosinstall src/.rosinstall
echo "configuration file copied"

# system dependency update
echo "start to install dependency"
git pull
./scripts/update.sh 

# install tools for build
sudo apt install python3-catkin-tools
sudo apt install python3-osrf-pycommon

# build
source /opt/ros/noetic/setup.bash

catkin_make -DPYTHON_EXECUTABLE=/usr/bin/python3

# setup World of Abu Dhabi
mkdir  ~/.gazebo
mkdir  ~/.gazebo/models
sudo apt install curl
curl -LO https://github.com/rudislabs/qualisys_ros/releases/download/v0.1/abu_dhabi.zip
unzip abu_dhabi.zip  -d ~/.gazebo/models/

# launch simulation
# under dir tii_ws
source devel/setup.bash
cd src/qualisys_ros/launch
roslaunch qualisys abu_dhabi.launch
