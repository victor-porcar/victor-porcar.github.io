#!/bin/bash

# Check if the path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_local_repo>"
    exit 1
fi
 
REPO_PATH="$1"

# Change to the repository directory
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Error: The provided path is not a valid Git repository."
    exit 1
fi

cd "$REPO_PATH" || exit

# Pull the latest changes
echo "Pulling latest changes..."
git pull origin

# Check for changes
if ! git diff --quiet; then
    echo "Changes detected. Committing and pushing..."
    
    # Add changes to staging
    git add .

    # Commit changes
    git commit -m "Automated commit: Updates from script"

    # Push changes
    git push origin
else
    echo "No changes to commit."
fi
 
echo "Script completed."