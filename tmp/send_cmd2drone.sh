#!/bin/bash

# open a new terminal

source /opt/ros/foxy/setup.bash
source fog_sw/ros2_ws/install/setup.bash

ros2 topic pub -t 1 /device_id_123abc/mavlinkcmd std_msgs/msg/String "data: takeoff"
ros2 topic pub -t 1 /device_id_123abc/mavlinkcmd std_msgs/msg/String "data: land"
