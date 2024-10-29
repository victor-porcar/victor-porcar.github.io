#!/bin/bash

./site/my-bookmarks/updateBookmarks.sh

./site/my-scripts/gitPullCommitPush/gitPullCommitPush.sh "./"

read -n 1 -s -r -p "Press any key to continue..."