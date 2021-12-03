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
  SESSION=sms
  set -- $(stty size) # $1 = rows $2 = columns
  tmux -2 new-session -d -s "$SESSION" -x "$2" -y "$(($1 - 1))" "exec less +F /tmp/$number" # $1 - 1 because tmux status line uses a row
  tmux select-window -t $SESSION:0
  tmux split-window -v -l 5 -t 0 "exec while true; do read input; echo $input > /tmp/text; cat /tmp/text | sxmo_modemsendsms.sh $number -; done"
  tmux -2 attach-session -t $SESSION
}

number_check
prettify
make_panes
