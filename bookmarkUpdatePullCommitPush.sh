#!/bin/bash

read -n 1 -s -r -p "Export Bookmarks from browser into $HOME/Bookmarks and PUSH ANY KEY"

./site/my-bookmarks/updateBookmarks.sh

./site/my-scripts/gitPullCommitPush/gitPullCommitPush.sh "./"
