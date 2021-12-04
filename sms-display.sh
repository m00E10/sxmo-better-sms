#!/bin/bash

number=$1
path=~/.local/share/sxmo/modem # This is where phone numbers are saved to

# If number is not provided as a positional argument, make TUI to allow user to
# select a number. Once selected, the program calls itself with the positional
# argument included, when this occurs we jump to our log prettifying function
function number_check {
  if [ -z $number ]; then
    make_tui
	else
		prettify
	fi
}

# We use whiptail to draw the TUI. Whiptail displays data in a static form
# though, so to ensure that this program works well on different devices we will
# dynamically generate the TUI menu function as its own script, menu.sh and then
# call it
function make_tui {
	echo '#!/bin/bash' > menu.sh
	echo "path=$path" >> menu.sh
	
	echo 'CHOICE=$(whiptail --menu "Number to text" 18 30 10 \' >> menu.sh

	# While loop to add all of the saved phone numbers to the TUI select menu
	counter=0
	amount=$(ls -1 $path | grep "+" | wc -l)
	# Option for user to add a new number to text, placed at the top
	echo "\"0.\" \"New Number\" \\" >> menu.sh
	while [ $counter -lt $amount ]; do
		((counter=counter+1))
		num=$(ls -1 $path | grep "+" | head -$counter | tail -1)
		echo "\"$counter.\" \"$num\" \\" >> menu.sh
	done

	((counter=counter+1))
	# Option for user to add a new number to text, repeated at the bottom
	echo "\"$counter.\" \"New Number\" 3>&1 1>&2 2>&3)" >> menu.sh
	# Resaves the choice, when selected CHOICE may be "4.", this saves it as "4"
	echo 'CHOICE=$(echo $CHOICE | rev | cut -c2- | rev)' >> menu.sh

	echo 'if [ -z "$CHOICE" ]; then' >> menu.sh
	echo '	echo "No option chosen"' >> menu.sh

	# If our first choice, the "New Number" option, draw an input box for the user
	# to input a new number. Also perform validation of the number. If the number
	# is not valid alert the user "Invalid Number" and return to the input box
	echo 'elif [ "$CHOICE" == "0" ]; then' >> menu.sh
	echo '	while true; do' >> menu.sh
	echo '		number=$(whiptail --inputbox "Enter number Ex: +11231231234" 10 30 3>&1 1>&2 2>&3)' >> menu.sh
	echo '		if [ "$(echo $number | wc -m)" == "13" ] && [ "$(echo $number | cut -c 1)" == "+" ] && [[ "$(echo $number | cut -c2-)" == ?(-)+([0-9]) ]] ; then' >> menu.sh
	echo '			break;' >> menu.sh
	echo '		elif [ "$(echo $number)" == "" ]; then' >> menu.sh
	echo '			break;' >> menu.sh
	echo '		else' >> menu.sh
	echo '			whiptail --msgbox "Invalid Number" 9 15' >> menu.sh
	echo '		fi' >> menu.sh
	echo '	done' >> menu.sh
	echo '	bash sms-display.sh $number' >> menu.sh

	# Do the same if the option was our last choice, again the "New Number" option
	echo "elif [ \"\$CHOICE\" == \"$counter\" ]; then" >> menu.sh
	echo '	while true; do' >> menu.sh
	echo '		number=$(whiptail --inputbox "Enter number Ex: +11231231234" 10 30 3>&1 1>&2 2>&3)' >> menu.sh
	echo '		if [ "$(echo $number | wc -m)" == "13" ] && [ "$(echo $number | cut -c 1)" == "+" ] && [[ "$(echo $number | cut -c2-)" == ?(-)+([0-9]) ]] ; then' >> menu.sh
	echo '			break;' >> menu.sh
	echo '		elif [ "$(echo $number)" == "" ]; then' >> menu.sh
	echo '			break;' >> menu.sh
	echo '		else' >> menu.sh
	echo '			whiptail --msgbox "Invalid Number" 9 15' >> menu.sh
	echo '		fi' >> menu.sh
	echo '	done' >> menu.sh
	echo '	bash sms-display.sh $number' >> menu.sh

	# If any other selection, save the selected number and recall our program with
	# that number as a positional argument. This will open the paned texting
	# interface
	echo 'else' >> menu.sh
	echo '	number=$(ls -1 $path | grep "+" | head -$CHOICE | tail -1)' >> menu.sh
	echo '	bash sms-display.sh $number' >> menu.sh
	echo 'fi' >> menu.sh

	bash menu.sh
}

# The default sms modem logs are very information heavy and don't provide a very
# readable user experience. This function makes them more readable.
function prettify {
	rm menu.sh # clean up our dynamically made TUI
  smslog=~/.local/share/sxmo/modem/$number/sms.txt

	# watch returns the following statement every 5 seconds, sed performs parsing
	# of the sms.txt file making it more readable, and then tee passes this output
	# to a new file at /tmp/$number, "&>/dev/null &" allows this statement to run
  #	in the background
  watch -n 5 "cat $smslog | sed -E '/^(Received|Sent) (from|to) \+[0-9]+ at/ s/ .*([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9:]{8}).*/        \1 \2/' | tee /tmp/$number" &>/dev/null &

	make_panes
}

# Draws the SMS interface through panes provided through terminal multiplexing
function make_panes {
	# Detach and lable our session, "sms", and read our prettified sms log file
  tmux new-session -d -s sms "exec less +F /tmp/$number"
	# To perform further operations we must select our session
  tmux select-window -t sms:0
	# This needs needs to be set as its own bash script, pane crashes when passing
  #	this as a oneliner to tmux exec
	echo "while true; do read input; echo \$input | sxmo_modemsendsms.sh $number - ; done" > read.sh
	# Reads input from the user, when input returned, we send the input to the
	# previously selected number
  tmux split-window -v -l 7 -t 0 "exec bash read.sh"
	# Now that the SMS panes have been drawn, we attach to this session
  tmux -2 attach-session -t sms
}

number_check
