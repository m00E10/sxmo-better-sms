#!/bin/bash

# TODO
# Add more thorough number verification

number=$1
path=~/tmp/sample-numbers/


function number_check {
  if [ -z $number ]; then
    make_tui
	else
		prettify
	fi
}

function make_tui {
	echo '#!/bin/bash' > menu.sh
	echo "path=$path" >> menu.sh
	echo 'CHOICE=$(whiptail --menu "Number to text" 18 50 10 \' >> menu.sh

	counter=0
	amount=$(ls -1 $path | grep "+" | wc -l)
	echo "\"0.\" \"New Number\" \\" >> menu.sh
	while [ $counter -lt $amount ]; do
		((counter=counter+1))
		number=$(ls -1 $path | grep "+" | head -$counter | tail -1)
		echo "\"$counter.\" \"$number\" \\" >> menu.sh
	done

	((counter=counter+1))
	echo "\"$counter.\" \"New Number\" 3>&1 1>&2 2>&3)" >> menu.sh
	echo 'CHOICE=$(echo $CHOICE | rev | cut -c2- | rev)' >> menu.sh

	echo 'if [ -z "$CHOICE" ]; then' >> menu.sh
	echo '	echo "No option chosen"' >> menu.sh
	echo 'elif [ "$CHOICE" == "0" ]; then' >> menu.sh
	echo '	number=$(whiptail --inputbox "Enter number Ex: +11231231234" 10 30 3>&1 1>&2 2&3' >> menu.sh
	echo '	bash sms-display.sh $number' >> menu.sh
	echo "elif [ \"\$CHOICE\" == \"$counter\" ]; then" >> menu.sh
	echo '	number=$(whiptail --inputbox "Enter number Ex: +11231231234" 10 30 3>&1 1>&2 2&3' >> menu.sh
	echo '	bash sms-display.sh $number' >> menu.sh
	echo 'else' >> menu.sh
	echo '	number=$(ls -1 $path | grep "+" | head -$CHOICE | tail -1)' >> menu.sh
	echo '	echo "placeholder. will call main script with $number"' >> menu.sh
	echo 'fi' >> menu.sh

	bash menu.sh

}

function prettify {
  smslog=~/.local/share/sxmo/modem/$number/sms.txt
  watch -n 5 "cat $smslog | sed -E '/^(Received|Sent) (from|to) \+[0-9]+ at/ s/ .*([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9:]{8}).*/        \1 \2/' | tee /tmp/$number" &>/dev/null &

	make_panes
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
