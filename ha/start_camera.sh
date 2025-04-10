#!/bin/bash
while true; do
    rpicam-vid -t 0 --inline --codec mjpeg --quality 95 --width 2592 --height 1944 --framerate 7 --listen -o tcp://0.0.0.0:8000 # 45% CPU
    echo "Camera crashed, restarting..."
    sleep 1
done
