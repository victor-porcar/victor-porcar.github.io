
## My site

This repository is my personal web site for public IT resources like Tech Talks, technical bookmarks and GitHub repos.

Please note that GitHub creates automatically a simple web application in repositories having its name as `<GIT_USER>.github.io`, where all pages with .md extension are converted into their corresponding HTML. The main page is `index.md` and the url is `https://<GIT_USER>.github.io`.
In my case `<GIT-USER>` is `victor-porcar`, so the url is:

 
[https://victor-porcar.github.io](https://victor-porcar.github.io)
 
### Structure of the site
The structure of this site is the following:

* images: required images for the site.
* my-notes: markdown files with my notes and scripts.
* my-scripts: useful scripts I built and used over the years
* my-techtalks: collection in markdown with the bulletpoints of my tech talks.
* my-bookmarks: my technical bookmarks in a pretty HTML format using [Bookmark2md](https://github.com/victor-porcar/Bookmark2md) See *Manage Bookmarks* section below
* public-docs: collection of documents which I find interesting.

In order to work locally with this site, please clone all repos in a working folder as follows:

### Steps to clone locally all repositories

Please follow these steps to do it:

#### create working folder, for example with name FSD
In this case let's use FSD
```
$ mkdir $HOME/FSD
```
#### download script `gitCloneAll.sh`
```
$ cd $HOME/FSD
$ curl https://raw.githubusercontent.com/victor-porcar/victor-porcar.github.io/refs/heads/master/site/my-scripts/gitCloneAll/gitCloneAll.sh > gitCloneAll.sh
$ chmod 700 $HOME/FSD/gitCloneAll.sh
``` 
    
#### execute the script `gitCloneAll.sh`
```
$ cd $HOME/FSD
$ ./gitCloneAll.sh victor-porcar $HOME/FSD <AUTHENTICATION_GITHUB_TOKEN>
```


### Manage Bookmarks

Let's assume you have exported your bookmarks as *HTML NETSCAPE-Bookmark-file-1" DOCTYPE* format from your browser in directory`$HOME/Bookmarks`.<br>
Let's assume you have all your technical bookmarks in folder "IT" of your bookmarks hierarchy.<br>
At this point you can execute:
 
```
$ cd $HOME/FSD/victor-porcar.github.io
$ ./site/my-bookmarks/updateBookmarks.sh
```
this will create or update three files:

*  `./site/my-bookmarks/generated/generated_PRETTY_HTML_IT.html`: pretty HTML version of the bookmarks under directory "IT"
*  `./site/my-bookmarks/generated/generated_MD_IT.md`: markdown GitHub flavour of the bookmarks under directory "IT"
*  `./site/my-bookmarks/generated/bookmarksIT.html`: html file importable file in any browser with the content of directory "IT"



