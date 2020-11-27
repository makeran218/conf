#!/bin/bash

# Helper script for the Deluge torrent client
# Intended to be run at torrent completion, using the 'torrent complete' event in the 'Execute' plugin.
#
# The basic idea is to hardlink the files that deluge has just finished downloading to a second directory.
# This allows you to configure deluge to automatically pause or delete torrents when they reach a given seed ratio,
# while also keeping a copy around for other reasons. For example, SyncThing could be used to propagate new downloads
# to a remote machine to be processed further. When processing has finished, and the file is deleted/moved out of the
# Syncthing folder, the remote Syncthing will propagate a deletion back to the original Synchting (on the machine
# running deluge).
#
# The end result is that the lifetime of files involved both in deluge's seeding process and the 'forward to somewhere
# else' process (e.g. via Syncthing) are decoupled, and can safely execute in parallel without needing to be aware of
# what the other is doing. And yet the net result is that the files will still be cleaned up automagically when both
# have finished their respective tasks.
#
# Note: if you use the Label plugin, note that if you change the location where completed torrents should be moved to,
#       remember that each label may also have a location stored in each which will also be need to be updated.
#
# Paul Chambers, Copyright (c) 2019.
#
# Made available under the Creative Commons 'BY' license
# https://creativecommons.org/licenses/by/4.0/
#

set -x

torrentId=$1
torrentName=$2
torrentPath=$3

# echo "$torrentId $torrentName $torrentPath" >> /tmp/torrent-complete.log

srcDir="/content/drive/"
destDir="/content/drive2/Torrents"

label="${torrentPath#$srcDir}"

# note that srcPath may be a file, not necessarily a
# directory. Which means the same is true for destPath.
srcPath="${torrentPath}/${torrentName}"
destPath="${destDir}/${torrentName}"

# We may be given a file or a directory. If it's a directory, it may contain one or more
# rar files, in which case we unpack each one directly into the destination hierarchy.
# Non-rar files are always hardlinked to the destination.

if [ -d "${srcPath}" ]
then
    # multiple rar files may be found in subdirectories, so handle each one, preserving hierarchy
    find "${srcPath}" -name '*.rar' -print0 | while read -d $'\0' rarFile
    do
        path="$(dirname "${rarFile}")"
        subDir="${path#$srcDir}"
        mkdir -p "${destDir}/${subDir}"
        unrar e -o+ "${rarFile}" "${destDir}/${subDir}"
    done

    # hardlink everything in the source directory (not rar-related), to the destination directory
    find "${srcPath}" -mindepth 1 ! -regex '.*\.r[a0-9][r0-9]' -print0 |  while read -d $'\0' nonRarFile
    do
        path="$(dirname "${nonRarFile}")"
        subDir="${path#$srcDir}"
        mkdir -p "${destDir}/${subDir}"
        ln -v "${nonRarFile}" "${destDir}/${subDir}"
    done
else
    # we were passed a single file, not a directory
    cp -la "${srcPath}" "${destPath}"
fi

# could unpack other archives here too, but it's preferable to decompress
# any already-compressed archives at the remote machine, not here.
