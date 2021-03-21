#!/bin/bash

# open a new terminal
source /opt/ros/foxy/setup.bash
source fog_sw/ros2_ws/install/setup.bash

export DRONE_DEVICE_ID=device_id_123abc

ros2 launch px4_mavlink_ctrl mavlink_ctrl.launch
