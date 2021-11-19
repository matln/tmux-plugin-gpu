#!/usr/bin/env bash

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value="$(tmux show-option -gqv "$option")"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

# "<" math operator which works with floats, once again based on awk
fcomp() {
  awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<=n2) exit 0; exit 1}'
}

# Reference: https://github.com/soyuka/tmux-current-pane-hostname/blob/master/scripts/shared.sh
get_ssh_cmd() {
	pgrep -flaP $(tmux display-message -p "#{pane_pid}") | sed -E 's/^[0-9]*[[:blank:]]*//'
}

ssh_connected() {
	# Get current pane command
	local cmd=$(tmux display-message -p "#{pane_current_command}")

	[ $cmd = "ssh" ] || [ $cmd = "sshpass" ]
}
