#
# ~/.bashrc
#

export PATH=~/bin:$PATH

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

function open() {
	# Wrap in parentheses to avoid seeing background task output
	(xdg-open "$@" >/dev/null 2>&1 &)
}

alias gs="git status"
function gp() {
	git pull && git add . && git commit -m "$1" && git push
}
