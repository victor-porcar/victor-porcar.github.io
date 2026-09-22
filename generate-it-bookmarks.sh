#!/bin/bash

# Generates the IT bookmarks page of this site from the current Chrome bookmarks, using Bookmark2html
# Asks for confirmation first; it waits for a key at the very end, so the result can be read
# Works from any directory: Bookmark2html is located through GITHUB_VICTOR_PORCAR

# Bookmark folder to export
FOLDER="IT"

# Chrome profile directory; can be overridden when calling: CHROME_PROFILE=... ./generate-it-bookmarks.sh
CHROME_PROFILE="${CHROME_PROFILE:-$HOME/.config/google-chrome/Default}"

# Candidate Chrome bookmarks files separated by ";": the first one that exists is used.
# Recent Chrome versions keep the account bookmarks in AccountBookmarks, older ones in Bookmarks
BOOKMARKS_FILE="$CHROME_PROFILE/AccountBookmarks;$CHROME_PROFILE/Bookmarks"

# Generated page, inside this repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OUTPUT_FILE="$SCRIPT_DIR/site/my-it-bookmarks/index.html"

# No backup of the Chrome bookmarks file: 0 backups to keep makes Bookmark2html ignore the directory
BACKUP_DIR="/tmp"
BACKUPS_TO_KEEP=0

finish() {
    echo
    read -n 1 -s -r -p "Press any key to finish..."
    echo
    exit "$1"
}

if [ -z "$GITHUB_VICTOR_PORCAR" ]; then
    echo "X  The GITHUB_VICTOR_PORCAR environment variable is not defined"
    finish 1
fi

BOOKMARK2HTML_JAR="$GITHUB_VICTOR_PORCAR/Bookmark2html/target/bookmark2html.jar"
if [ ! -f "$BOOKMARK2HTML_JAR" ]; then
    echo "X  bookmark2html.jar not found at: $BOOKMARK2HTML_JAR"
    echo "   Build it with \"mvn clean package\" in $GITHUB_VICTOR_PORCAR/Bookmark2html"
    finish 1
fi

if ! command -v java > /dev/null; then
    echo "X  java not found: install Java 17 or later"
    finish 1
fi

read -r -p "Are you sure to generate IT bookmarks with the current Chrome Bookmarks [Yy]? " ANSWER
if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "Aborted: nothing was generated"
    finish 0
fi

java -jar "$BOOKMARK2HTML_JAR" "$BOOKMARKS_FILE" "$OUTPUT_FILE" "$FOLDER" "$BACKUP_DIR" "$BACKUPS_TO_KEEP"
finish $?
