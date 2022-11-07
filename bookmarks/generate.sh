#!/bin/bash

# please set this variable properly for your environment

BOOKMARK2MD_HOME="$HOME/victormpcmun/Bookmark2md"
BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY="$HOME/Bookmarks"

#  ======================================================


PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
BOOKMARK_FOLDER_NAME="IT"
GENERATED_FOLDER="$PARENT_PATH/generated"
MARKDOWN_FILE_NAME="generated_MD_FSD.md"
HTML_PRETTY_FILE_NAME="generated_HTML_FSD.html"
RAW_IMPORTABLE_HTML_FILE="bookmarksFSD.html"

#  ======================================================



LATEST_BOOKMARK_EXPORTED_FILE=`ls $BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY -rt  | tail -n 1`
 
$BOOKMARK2MD_HOME/bookmark2md.sh "$BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY/$LATEST_BOOKMARK_EXPORTED_FILE"  "$GENERATED_FOLDER" "$MARKDOWN_FILE_NAME"  "$HTML_PRETTY_FILE_NAME"  "$RAW_IMPORTABLE_HTML_FILE" $BOOKMARK_FOLDER_NAME

