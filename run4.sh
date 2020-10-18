find '/content/drive/'  -type d -name ".unwanted" -exec rm -rf "{}" \;
find '/content/drive/' -type d -empty -delete;
rclone move "$1" "baros4-campur:/Torrents/${2%.*}" --checkers 20 --fast-list -v --log-file=/content/rclone.log --tpslimit 20 --transfers 20 --exclude '.unwanted/' --delete-empty-src-dirs
