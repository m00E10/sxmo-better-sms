#!/bin/bash

number=$1
echo "Positional arg = $numberi"

function send_text {
  while true; do
    read input
    # sxmo command to send $input
    echo $input
    unset $input
   done
}

send_text
