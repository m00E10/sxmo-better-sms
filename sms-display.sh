#!/bin/bash

number=$1
echo "Positional arg = $number"

function number_check {
  if [ -z $number ]; then
    echo "Please provide a phone number as a parameter"
    exit
  fi
}

function prettify {
  smslog=sample-sms.log # ~/.local/share/sxmo/$number/sms.txt
  cat $smslog | sed 's/from//g' | sed 's/to/    /g' | sed 's/+\w\+//' \
   sed 's/at//g' | sed 's/T/ /g' | sed 's/[[:digit:].]*\:$//' | \
   sed 's/[[:digit:].]*\:$//' | sed 's/-$//' | sed 's/-$//' | sed 's/+$//' \
   > /tmp/$number
}

function make_panes {
  SESSION=sms
  # $1 = rows $2 = columns
  set -- $(stty size) 
  # $1 - 1 because tmux status line uses a row
  tmux -2 new-session -d -s "$SESSION" -x "$2" -y "$(($1 - 1))" \
   "exec less +F $smslog"
  tmux select-window -t $SESSION:0
  #tmux split-window -h "exec bottom-pane.sh $number"
  tmux split-window -v -l 5 -t 0 'exec echo "hello"'
  tmux -2 attach-session -t $SESSION
}
