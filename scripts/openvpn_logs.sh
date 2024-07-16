#!/bin/bash
if tmux has-session -t openvpn 2>/dev/null; then
    tmux capture-pane -t openvpn -p
else
    echo "No active VPN connections"
    exit 1
fi