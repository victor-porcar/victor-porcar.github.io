#!/bin/bash

./updateBookmarks.sh


git pull 
git add .
git commit -m "update of bookmarks"
git push origin master
read -p "Press enter to continue" 
