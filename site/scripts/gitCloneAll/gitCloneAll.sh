
#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage gitCloneAll.sh <REPO_NAME> <LOCAL_DIRECTORY> <AUTHENTICATION_GITHUB_TOKEN>"
    echo "Example: gitCloneAll.sh victor-porcar \"/home/victor.porcar/my_repository\" ghp_MpcYKKKdlqFQirdH15JcH3hwia45B4265DzQ"
    exit 1
else
    name=$1
fi
 
dir=$2
GITHUB_TOKEN=$3


if [[ ! -e $dir ]]; then
    mkdir $dir
elif [[ ! -d $dir ]]; then
    echo "$dir already exists but is not a directory" 1>&2
    exit -1;
fi

cd $dir

curl "https://api.github.com/users/$name/repos?page=1&per_page=1000" --header "Authorization: Bearer $GITHUB_TOKEN" | grep -e 'clone_url*' | cut -d \" -f 4 | xargs -L1 git clone
 
 

exit 0
