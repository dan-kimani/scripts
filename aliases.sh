alias open='xdg-open'
alias push='git push'
alias update='sudo apt update'
alias upgrade='sudo apt upgrade'
alias add='git add'
alias commit='git commit'
alias status='git status'
alias pull='git pull'
alias t1='tree -L 1'
alias t2='tree -L 2'
alias install='sudo apt install'
alias dev='yarn dev'
alias build='yarn build'
alias branch='git branch'

parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# only show current working directory and display current git branch
PS1='\[\033[36m\]\W\[\033[00m\] \[\033[00;32m\]$(parse_git_branch)\[\033[00;00m\]$ '
