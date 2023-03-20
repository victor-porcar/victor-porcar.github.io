#!/bin/bash


THIS_FOLDER=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd $THIS_FOLDER
./updateBookmarks.sh


git pull 
git add .
git commit -m "update of bookmarks"
git push origin master
read -p "Press enter to continue" 
