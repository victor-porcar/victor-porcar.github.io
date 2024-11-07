
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



## Create Local directory with all my Repos

In order to have a local copy of all github repos (including this one), lets say for example in local path `$HOME/FSD/mygithub` for linux or `d:\victor-master\fsd\mygithub` for Windows
To achieve this, please follow these steps:

- Create directory `$HOME/FSD/mygithub` for linux or `d:\victor-master\fsd\mygithub` for Windows.
- Download  script  `gitCloneOrPullAll.sh' or `gitCloneOrPullAll.cmd' accordingly and execute as follows:

For Linux
```
$ cd /tmp
$ curl https://raw.githubusercontent.com/victor-porcar/victor-porcar.github.io/refs/heads/master/site/my-scripts/gitCloneOrPullAll/gitCloneOrPullAll.sh > gitCloneOrPullAll.sh
$ chmod 700 $HOME/FSD/gitCloneOrPullAll.sh
$ ./gitCloneOrPull.sh "victor-porcar" "$HOME/FSD/mygithub" <GITHUB_TOKEN>
$ rm ./gitCloneOrPull.sh
```
For Windows
```
D:\> cd d:\temp
D:\TEMP> curl https://raw.githubusercontent.com/victor-porcar/victor-porcar.github.io/refs/heads/master/site/my-scripts/gitCloneOrPullAll/gitCloneOrPullAll.sh > gitCloneOrPullAll.sh
D:\TEMP> gitCloneOrPull "victor-porcar" "d:\victor-master\fsd\mygithub" <GITHUB_TOKEN>
D:\TEMP> del gitCloneOrPull.cmd
```
This will clone all repositories of github user "victor-porcar" in the corresponding local directory



### Manage Bookmarks
In order to manage bookmarks,  it is necessary to have locally the repository Bookmark2MD, so the previous steps to create Local directory with all my Repos has to be done

Let's assume you have exported your bookmarks as *HTML NETSCAPE-Bookmark-file-1" DOCTYPE* format from your browser in directory`$HOME/Bookmarks`.<br>
Let's assume you have all your technical bookmarks in folder "IT" of your bookmarks hierarchy.<br>
At this point you can execute:
 
```
$ $HOME/FSD/victor-porcar.github.io/site/my-bookmarks/updateBookmarks.sh
```
this will create or update three files:

*  `./site/my-bookmarks/generated/generated_PRETTY_HTML_IT.html`: pretty HTML version of the bookmarks under directory "IT"
*  `./site/my-bookmarks/generated/generated_MD_IT.md`: markdown GitHub flavour of the bookmarks under directory "IT"
*  `./site/my-bookmarks/generated/bookmarksIT.html`: html file importable file in any browser with the content of directory "IT"

Remember after creating for the first time or updating those files to commit and push them!

