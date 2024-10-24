
This repository is my personal web sit for public IT resources like Tech Talks, technical bookmarks and GitHub repos

Please note that GitHub creates automatically a simple web application in repositories having its name as `<GIT_USER>.github.io`, where all pages with .md extension are converted into their corresponding HTML. The main page is `index.md` and the url is `https://<GIT_USER>.github.io`.
In my case `<GIT-USER>` is `victor-porcar`

The structure of this site is the following:

* images: required images for the site.
* my-notes: markdown files with my notes and scripts.
* my-scripts: useful scripts I built and used.
* my-techtalks: collection in markdown with the bulletpoints of my tech talks.
* my-bookmarks: my technical bookmarks in a pretty HTML format (using [Bookmarkd2md]([https://link-url-here.org](https://github.com/victor-porcar/Bookmark2md) See details below
* public-docs: collection of documents which I find interesting.


### Manage Bookmarks


### Steps to clone locally all repositories

In order to clone all repositories at the same time, please follow this steps:

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

