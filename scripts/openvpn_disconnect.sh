#!/bin/bash

if tmux has-session -t openvpn 2>/dev/null; then
    tmux send-keys -t openvpn C-c

    if tmux has-session -t openvpn 2>/dev/null; then
        tmux kill-session -t openvpn
    fi
    echo "Killed active VPN connection"
else
    echo "No active VPN connections"
    exit 1
fi
exit 0