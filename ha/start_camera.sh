#!/bin/bash
while true; do
    rpicam-vid -t 0 --inline --codec h264 --width 1920 --height 1080 --bitrate 10000000 --listen -o tcp://0.0.0.0:8000
    echo "Camera crashed, restarting..."
    sleep 1
done
