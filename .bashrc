#
# ~/.bashrc
#

alias s="$HOME/bin/launch_sway.sh"
alias shut="shutdown now"
alias wifi="(sudo -E iwgtk >/dev/null 2>/dev/null &)"

export PATH=~/bin:$PATH
export XDG_CURRENT_DESKTOP=sway

source ~/.config/colors.sh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

export PS1='[\u@\h $(echo $(dirname \w)|sed -e "s;\(/.\)[^/]*;\1;g")/$(basename \w)]\$ '

function open() {
	# Wrap in parentheses to avoid seeing background task output
	(xdg-open "$@" >/dev/null &)
}

alias gs="git status"
function gp() {
	git pull && git add . && git commit -m "$1" && git push
}

function get_wins() {
	search="app_id"
	if [ -n "$1" ]; then
		search=$1
	fi
	swaymsg -t get_tree | jq ".." | grep -P "^  \"$search"
}

update_system_on_boot.sh
