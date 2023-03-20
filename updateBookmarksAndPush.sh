#!/bin/bash

./generateBoomarks.sh
git add .
git commit -m "update of bookmarks"
git push origin master 
