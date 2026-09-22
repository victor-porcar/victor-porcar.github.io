#!/bin/bash

# Generates the IT bookmarks page of this site from the current Chrome bookmarks, using Bookmark2html
# Asks for confirmation first and, once generated, whether to commit and push the page
# It waits for a key at the very end, so the result can be read
# Works from any directory: Bookmark2html is located through GITHUB_VICTOR_PORCAR

# Bookmark folder to export
FOLDER="IT"

# Chrome profile directory; can be overridden when calling: CHROME_PROFILE=... ./generate-it-bookmarks.sh
CHROME_PROFILE="${CHROME_PROFILE:-$HOME/.config/google-chrome/Default}"

# Candidate Chrome bookmarks files separated by ";": the first one that exists is used.
# Recent Chrome versions keep the account bookmarks in AccountBookmarks, older ones in Bookmarks
BOOKMARKS_FILE="$CHROME_PROFILE/AccountBookmarks;$CHROME_PROFILE/Bookmarks"

# This repository and the generated page inside it
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OUTPUT_IN_REPO="site/my-it-bookmarks/bookmarks${FOLDER}.html"
OUTPUT_FILE="$REPO_DIR/$OUTPUT_IN_REPO"

# Message of the commit made when the page is pushed
COMMIT_MESSAGE="Update IT bookmarks"

# No backup of the Chrome bookmarks file: 0 backups to keep makes Bookmark2html ignore the directory
BACKUP_DIR="/tmp"
BACKUPS_TO_KEEP=0

finish() {
    echo
    read -n 1 -s -r -p "Press any key to finish..."
    echo
    exit "$1"
}

# Commits only the generated page (nothing else that may be modified in the repository)
# and pushes it, after bringing the latest changes; returns 0 when done or nothing to do
commit_and_push() {
    if ! command -v git > /dev/null; then
        echo "X  git not found"
        return 1
    fi
    if [ -z "$(git -C "$REPO_DIR" status --porcelain -- "$OUTPUT_IN_REPO")" ]; then
        echo "The generated file is the same as the committed one: nothing to commit"
        return 0
    fi
    if ! git -C "$REPO_DIR" pull --ff-only; then
        echo "X  git pull failed: resolve it by hand, the generated file is left uncommitted"
        return 1
    fi
    git -C "$REPO_DIR" add -- "$OUTPUT_IN_REPO" || return 1
    git -C "$REPO_DIR" commit -m "$COMMIT_MESSAGE" -- "$OUTPUT_IN_REPO" || return 1
    if ! git -C "$REPO_DIR" push; then
        echo "X  git push failed: the commit is done locally, push it by hand"
        return 1
    fi
    echo "OK Generated bookmark file committed and pushed"
}

if [ -z "$GITHUB_VICTOR_PORCAR" ]; then
    echo "X  The GITHUB_VICTOR_PORCAR environment variable is not defined"
    finish 1
fi

BOOKMARK2HTML_JAR="$GITHUB_VICTOR_PORCAR/bookmark2html/target/bookmark2html.jar"
if [ ! -f "$BOOKMARK2HTML_JAR" ]; then
    echo "X  bookmark2html.jar not found at: $BOOKMARK2HTML_JAR"
    echo "   Build it with \"mvn clean package\" in $GITHUB_VICTOR_PORCAR/bookmark2html"
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

if ! java -jar "$BOOKMARK2HTML_JAR" "$BOOKMARKS_FILE" "$OUTPUT_FILE" "$FOLDER" "$BACKUP_DIR" "$BACKUPS_TO_KEEP"; then
    finish 1
fi

echo
read -r -p "Do you want to commit and push the generated bookmark file [Yy]? " ANSWER
if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "Not committed: the generated file is only in the working copy"
    finish 0
fi

commit_and_push
finish $?
