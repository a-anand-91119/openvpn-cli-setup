#!/bin/bash 

# TODO: figure out which network interface is being used by staging and prod
# TODO: add script to see network activity from those interfaces

# login to bitwarden cli 
export BW_SESSION="<PUT_YOUR_BW_SESSION_KEY_HERE>"

# folder to dump the openvpn std outs
rootFolder="<ROOT_FOLDER_CONTAINING_THE_SCRIPTS>"

# ascii arts for different environments
staging="

  ___ _____ _   ___ ___ _  _  ___  __   _____ _  _ 
 / __|_   _/_\ / __|_ _| \| |/ __| \ \ / / _ \ \| |
 \__ \ | |/ _ \ (_ || || .\` | (_ |  \ V /|  _/ .\` |
 |___/ |_/_/ \_\___|___|_|\_|\___|   \_/ |_| |_|\_|

                                                   
"
production="

  ___ ___  ___  ___  _   _  ___ _____ ___ ___  _  _  __   _____ _  _ 
 | _ \ _ \/ _ \|   \| | | |/ __|_   _|_ _/ _ \| \| | \ \ / / _ \ \| |
 |  _/   / (_) | |) | |_| | (__  | |  | | (_) | .\` |  \ V /|  _/ .\` |
 |_| |_|_\\\\___/|___/ \___/ \___| |_| |___\___/|_|\_|   \_/ |_| |_|\_|
                                                                     
      
"

# bitwarden item ids based on environment
if [ $1 = "stage" ]; then 
    itemId="BW_ITEM_ID_FOR_ENVIRONMENT_NAMED_STAGE"
    envName="stage"
    ascii=$staging
elif [ $1 = "prod" ]; then
    itemId="BW_ITEM_ID_FOR_ENVIRONMENT_NAMED_PROD"
    envName="prod"
    ascii=$production
else
    echo "Invalid environment [$1] provided"
	exit 1
fi
laptopItem="BW_ITEM_ID_FOR_SUDO_PASSWORD"

# kill any existing vpn connections
if tmux has-session -t openvpn 2>/dev/null; then 
	tmux send-keys -t openvpn C-c
    if tmux has-session -t openvpn 2>/dev/null; then
        tmux kill-session -t openvpn
    fi
	echo "Closed existing session..."
fi


# start a new tmux session (sudo only works with openvpn cli)
# TODO: figure out a way to run this without root
# tmux new-session -d -s openvpn "sudo openvpn --config ${rootFolder}/${envName}.ovpn --auth-user-pass ${rootFolder}/${envName}_cred.txt"
tmux new-session -d -s openvpn "sudo bash -c 'openvpn --config ${rootFolder}/${envName}.ovpn'"

# sending sudo password
laptopPassword=$(bw get password "${laptopItem}") 
tmux send-keys -t openvpn "${laptopPassword}"
tmux send-keys -t openvpn Enter

# sending username
username=$(bw get username "${itemId}")
tmux send-keys -t openvpn "${username}"
tmux send-keys -t openvpn Enter

# sending password
password=$(bw get password "${itemId}")
tmux send-keys -t openvpn "${password}"
tmux send-keys -t openvpn Enter

# sending totp
totp=$(bw get totp "${itemId}")
tmux send-keys -t openvpn "${totp}"
tmux send-keys -t openvpn Enter

# tail the logs to check whether connection is successful or not
success=false
# spinner shamelessly copied from stackoverflow
spin='-\|/'
i=0
while true; do
	# see had to even lower the sleep interval just to get the stupid spinner to show properly
	sleep .1
	i=$(( (i+1) %4 ))
	printf "\rWaiting for ${envName} vpn connection to be established...${spin:$i:1}"

	# to handle cases when the session gets terminated
	# TODO: determine why it gets terminated and fix it.
	if tmux has-session -t openvpn 2>/dev/null; then 
		
		# capture stdout to a file
		tmux capture-pane -t openvpn -p > "${rootFolder}/vpn.log"
		# check whether vpn has been connected or not
		if grep -q "Initialization Sequence Completed" "${rootFolder}/vpn.log"; then
			printf "\rOpenvpn initialization sequence completed\n"
	    	success=true
	    	break
	  	fi
	else
		printf "\rOpenvpn session terminated abruptly...\n"
		break  
	fi

  	# 60 seconds timeout
  	elapsed=$((elapsed + 1))
  	if [ "$elapsed" -ge 600  ]; then  
    	printf "\rOpenvpn didn't start in time....\n"
    	break
  	fi
done

# because i can
if $success; then
	printf "\r*** Connected to ${envName} vpn *** "
	echo "$ascii" > "${rootFolder}/connected.vpn"
	exit 0
else
	printf "\r*** Failed to connect to ${envName} vpn. Please check logs*** "
	exit 1
fi
