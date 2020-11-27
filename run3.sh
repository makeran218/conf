
rclone move "$1" "baros3-campur:/Torrents/${2%.*}" --checkers 20 --log-file=/content/rclone.log --fast-list -v --tpslimit 20 --transfers 20 --exclude '.unwanted/' --delete-empty-src-dirs
