
This repository is my personal web for public IT resources like Tech Talks, technical bookmarks and GitHub repos

Please note that GitHub creates automatically a simple web application in repositories having its name as `<GIT_USER>.github.io`, where all pages with .md extension are converted into their corresponding HTML. The main page is `index.md` and the url is `https://<GIT_USER>.github.io`.
In my case `<GIT-USER>` is `victor-porcar`

### Steps to clone locally all my repositories

#### create working folder, for example with name FSD3
    mkdir $HOME/FSD3

#### download script `gitCloneAll.sh`

 
    $ cd $HOME/FSD3
    $ curl https://raw.githubusercontent.com/victor-porcar/victor-porcar.github.io/refs/heads/master/site/my-scripts/gitCloneAll/gitCloneAll.sh > gitCloneAll.sh
    chmod 700 $HOME/FSD3/gitCloneAll.sh
 
    
#### execute the script `gitCloneAll.sh`

    $ cd $HOME/FSD3
    $ ./gitCloneAll.sh victor-porcar $HOME/FSD3 <AUTHENTICATION_GITHUB_TOKEN>





STEPS to install and use it



Special repository victor-porcar.github.io

