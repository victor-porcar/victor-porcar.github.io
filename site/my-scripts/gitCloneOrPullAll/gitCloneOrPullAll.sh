#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: gitCloneOrPullAll.sh <USER_NAME> <LOCAL_DIRECTORY> <AUTHENTICATION_GITHUB_TOKEN>"
    echo "Example: gitCloneOrPullAll.sh victor-porcar \"/home/victor.porcar/my_repository\" ghp_MpcYKKKdlqFQirdH15JcH3hwia45B4265DzQ"
    exit 1
else
    name=$1
fi

dir=$2
GITHUB_TOKEN=$3

# Check if the directory exists and create it if it doesn't
if [[ ! -e $dir ]]; then
    mkdir -p "$dir" || { echo "Failed to create directory: $dir"; exit 1; }
elif [[ ! -d $dir ]]; then
    echo "$dir already exists but is not a directory" 1>&2
    exit 1
fi

cd "$dir" || { echo "Failed to change directory to $dir"; exit 1; }

# Get repositories
repos=$(curl "https://api.github.com/user/repos" --header "Authorization: Bearer $GITHUB_TOKEN" | grep -e 'clone_url*' | cut -d \" -f 4 | sed  "s/https:\/\//https:\/\/$GITHUB_TOKEN@/g")

# Clone or pull each repository
for repo in $repos; do
    repo_name=$(basename "$repo" .git)

    if [ -d "$repo_name" ]; then
        echo "Repository '$repo_name' already exists. Pulling latest changes..."
        cd "$repo_name" || { echo "Failed to change directory to $repo_name"; exit 1; }
        git pull || { echo "Failed to pull latest changes for '$repo_name'"; exit 1; }
        cd ..
    else
        echo "Cloning repository '$repo_name'..."
        git clone "$repo" || { echo "Failed to clone '$repo_name'"; exit 1; }
    fi
done

echo "All repositories processed successfully."
exit 0
