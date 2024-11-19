#!/bin/bash

# Check if a directory is provided as a parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <directory_to_compress>"
  exit 1
fi

# Get the directory from the parameter
directory_to_compress="$1"

# Check if the given directory exists
if [ ! -d "$directory_to_compress" ]; then
  echo "Error: '$directory_to_compress' is not a valid directory."
  exit 2
fi

# Traverse the directory and create a zip for each file
find "$directory_to_compress" -type f | while read -r file; do
  # Get the base name of the file (without the directory path)
  base_name=$(basename "$file")
  
  if [[ "$base_name" == *.zip ]]; then
    echo "$base_name is already in ZIP"
    continue
  fi

  # Create a zip file with the same name as the file, but with a .zip extension
  # zip -9 -q "${file}.zip" "$file"
  xz --keep --force "$file"

  # Check if the zip command was successful
  if [ $? -eq 0 ]; then
    echo "File '$file' has been successfully compressed to '${file}.zip'. Deleting the original file."
    
    # If the zip was successful, delete the original file
    rm -f "$file"
    
    # Check if the file deletion was successful
    if [ $? -eq 0 ]; then
      echo "Original file '$file' deleted."
    else
      echo "Error: Failed to delete the original file '$file'."
    fi
  else
    echo "Error: Failed to compress '$file'."
  fi
done