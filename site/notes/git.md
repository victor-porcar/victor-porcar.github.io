


## Create a GitHub Token

Let's create a "classic" github token for an existing account. 

1) goto https://github.com/settings/apps
2) choose tokens classic
3) generate new token
4) select only "repo" with all its children, which is enough to push later
5) set a name for your token


NOTE: this token will apply for all repositories in the account


## Clone a project with token

If a project is cloned with token, then later it is not necessary to enter name/password to push commits, to do this:

`git clone https://<TOKEN>@github.com/victor-porcar/victor-porcar.github.io`

then set the name and the account id (email) to push the commits for this project

`git config user.name "victor-porcar"`

`git config user. email "you@example.com"`

These values can be set globally, so they apply for all git projects

`git config --global user.name "victor-porcar"`

`git config --global user. email "you@example.com"`
