#!/bin/bash

# folder to dump the openvpn std outs
rootFolder="<ROOT_FOLDER_CONTAINING_THE_SCRIPTS>"

if tmux has-session -t openvpn 2>/dev/null; then
   cat "${rootFolder}/connected.vpn"
else
    echo "No active VPN connections"
    exit 1
fi