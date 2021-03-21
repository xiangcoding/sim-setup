#!/bin/bash

cd px4-firmware
git tag -d px4_sitl_pre181220 
make px4_sitl_rtps  gazebo_ssrc_fog_x 
