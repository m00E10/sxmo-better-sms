#!/bin/bash

number=$1

function number_check {
  if [ -z $number ]; then
    echo "Please provide a phone number as a parameter"
    exit
  fi
}

function prettify {
  smslog=~/.local/share/sxmo/modem/$number/sms.txt
  watch -n 5 "cat $smslog | sed -E '/^(Received|Sent) (from|to) \+[0-9]+ at/ s/ .*([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9:]{8}).*/        \1 \2/' | tee /tmp/$number" &>/dev/null &
}

function make_panes {
  tmux new-session -d -s sms "exec less +F /tmp/$number"
  tmux select-window -t sms:0
	# This needs needs to be set as its own bash script, pane crashes when passing this as a oneliner to tmux exec
	echo "while true; do read input; echo \$input | sxmo_modemsendsms.sh $number - ; done" > read.sh
  tmux split-window -v -l 7 -t 0 "exec bash read.sh"
  tmux -2 attach-session -t sms
}

number_check
prettify
make_panes
