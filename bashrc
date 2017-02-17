#!/bin/bash

# This script is something I've compiled over the course of my year and a half at Wayfair.
# It's not intended to be an end-all solution to all of your bash problems, but in my
# opinion it's a good a place as any to find some neat tricks when working with our code.

# Going line-by-line, I'll explain what each thing does and how it relates to the rest of
# the file. If you have any comments or suggestions, feel free to let me know! I've
# borrowed ideas from a number of people and I will be the first to admit that I am not
# the resident authority on Bash.

shopt -s expand_aliases
#if not running interactively, don't do anything
[[ "$-" != *i* ]] && return

####Mac Only
# This gives you a nice, colored, terminal (for things other than the prompt)

export CLICOLOR=1

# --------- Utility Aliases --------- #
# overrides grep with some regularly used flags
alias grep='grep -lnr --color'

####Color Variables:
# These are used to decorate outputs later on.
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

# Gets the git branch name
# Needed here because it is used to customize the command prompt
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Customize your prompt: The hope here is that it will output like this: (colors not displayed)
# * urname@machineName:  /Users/[user]/[current]/[directory]/[path]  ([branch_name])

if [ ${_OLD_VIRTUAL_PS1:0:2}=='\n' ]; then
  export PS1="\n${GREEN}\u@\h: ${YELLOW} \$PWD ${CYAN}\$(parse_git_branch) ${NC} \n$ "
else
  export PS1="\n${RED}[$VIRTUAL_ENV] ${GREEN}\u@\h: ${YELLOW} \$PWD ${CYAN}\$(parse_git_branch) ${NC} \n$ "
fi


#### Variables for use in functions
# I use these variables as part of functions to give me some output on the page (styled
# nicely). Your mileage may vary, but for your own use, the `printf whatever` section
printstatus="printf ${CYAN}Status:${NC}\n"
printbranch="printf ${CYAN}Branches:${NC}\n"

# --------- Base Commands --------- #
# I really hate typing: `vim ~/.bashrc` and `source ~/.bashrc`, so I made it `ba` and `so`.
# I had the sourcing print something just in case it gets stuck somewhere
BASHRCLOCATION="/Users/akoziak/.bashrc"
alias ba="vim ${BASHRCLOCATION}"
alias so="printf '${PURPLE}Sourcing...${NC}' && source ${BASHRCLOCATION}"

#### Repo directories
# This is sort of the meat and potatoes of the rest of the commands. Almost everything uses
# this. The `${WORKLOCATION}` variable is also usable everywhere, not just here. It is the
# full root path to your working directory (where your git repos are)
# make sure you update this!
WORKLOCATION="/Users/akoziak/Wayfair/"

# A list of the repos currently being used. If you want to implement some sort of project-based
# repo set, make this a variable that gets changed based on workspace.
REPOS="php resources templates"

# makes the aliases: gophp gores gotem
for repo in ${REPOS}
do
  # shortens the repository names to 3 characters
  short=${repo:0:3}
  # creates an alias per repository that will change directory.
  # Example output:
  # alias gophp="cd /Users/akoziak/Wayfair/php"
  alias go$short="cd ${WORKLOCATION}$repo"
done

all_repos () {
  # at the end of this function, we want to return to the directory the command was run from
  local current_location=$(PWD)
  # bash interprets REPOS as a list, separated by spaces
  for repo in ${REPOS}
  do
    # Output the name of the repo it's working with
    printf "\n${PURPLE}$repo${NC}\n"
    # go there. This doesn't use the aliases because it'd be more verbose to figure out which one
    cd ${WORKLOCATION}$repo
    # every command typed in after 'all_repos'
    for arg in "$@"
    do
      # run the command. BE CAREFUL
      $arg
    done
    # printed to indicate that it's done with this directory
    printf "${PURPLE}/$repo${NC}\n"
  done
  # return to the original directory
  cd $current_location
}

#### Use cases of `all_repos`
# `all_repos "git status"`
# `all_repos "git checkout master" "git fetch" "git pull"`
# normally this should be used within functions here, but it can be run from the command line
# independently

# --------- Git Commands --------- #
alias gitconf="git config --list"

# ---- logs ---- #
alias gitlog="git log --oneline --graph" # prettifies the log
alias gitlogchange="git log --oneline -p" # actual changes
alias gitlogstat="git log --oneline --stat" # number of lines changed
alias gitloggraph="git log --oneline --graph" # graph view of branches

# ---- general ---- #
alias gits="git status"
alias gitc="git commit -m"
alias gitp="git push -u origin HEAD"
alias gitac="git add -A && git commit -m"
alias gitcleanup="git gc --auto --prune" # shouldn't need to do this
alias gitprune="git remote prune origin" # not really necessary to do unless you have a large codebase
alias diffn="git diff --name-only origin/master"
alias branch='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cred%cr%Creset" $k|head -n 1`\\t$k;done|sort -r'
br="git branch -lvv"

# ------ functions ------ #
gitm () { git fetch && git merge origin/master; }
gitpulla () { all_repos "git pull"; }
branches () { all_repos "$printbranch" "$br"; }
stats () { all_repos "$printstatus" "git status"; }
scratch () { all_repos "git checkout master" "git prune" "git pull"; }
pruny () { all_repos "git remote prune origin"; }
mom () { all_repos "gitm" "git prune"; }
gitpa () { all_repos "git push -u origin HEAD"; }


# ------ Complicated Functions ------ #
# --- new feature: checks out given branch name on each repo
newf () { all_repos "git checkout master" "git pull" "git checkout -b $1 origin/master"; }
# --- old feature: checks out given branch name from an existing remote branch's tip
oldf () { all_repos "git fetch" "git checkout -b $1 origin/$1"; }
# --- go to branches: checks out given branch on each repo
gobr () { all_repos "git checkout $1"; }
# --- delete branches. BE CAREFUL
delbr () { all_repos "git checkout master" "git branch -D $1"; }
# --- rename branches
renbr () { all_repos "git branch -m $1"; }
