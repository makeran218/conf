#!/bin/bash
find '/content/drive/'  -type d -name ".unwanted" -exec rm -rf "{}" \;
find '/content/drive/' -type d -empty -delete;
lopo = "${2%.*}"
rclone move "$1" "baros-campur:/Torrents/$lopo" --checkers 20 --fast-list -v --tpslimit 20 --transfers 20 --exclude '.unwanted/' --log-file=/content/rclone.log --delete-empty-src-dirs

