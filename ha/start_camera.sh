#!/bin/bash
while true; do
#    rpicam-vid -t 0 --inline --codec libav --libav-format h264 --libav-video-codec libx264 --libav-video-codec-opts "preset=ultrafast;crf=23" --width 2592 --height 1944 --framerate 7 --listen -o tcp://0.0.0.0:8000
    rpicam-vid -t 0 --inline --codec h264 --width 1980 --height 1024 --framerate 30 --bitrate 300000000 --listen -o tcp://0.0.0.0:8000
#    rpicam-vid -t 0 --inline --codec libav --libav-format h264 --libav-video-codec libx264 --libav-video-codec-opts "preset=ultrafast;crf=23" --width 2000 --height 1500 --framerate 7 --listen -o tcp://0.0.0.0:8000
#    rpicam-vid -t 0 --inline --codec mjpeg --quality 95 --width 2592 --height 1944 --framerate 7 --listen -o tcp://0.0.0.0:8000 # 45% CPU
    echo "Camera crashed, restarting..."
    sleep 1
done
